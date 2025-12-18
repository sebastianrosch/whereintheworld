//
//  LocationController.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 15/11/2022.
//

import Foundation
import Cocoa
import SwiftUI
import CoreLocation
import CoreWLAN

protocol LocationControllerDelegate {
    func locationChanged(location: String)
    func setSlackStatus(statusText: String, withEmoji emoji: String, withExpiration expiration: Int)
}

class LocationController: NSObject, CLLocationManagerDelegate {
    private var delegate:LocationControllerDelegate?
    private let manager:CLLocationManager
    private let geocoder = CLGeocoder()
    private var isGeocoding:Bool = false
    private var lastGeocodeAttempt:Date? = nil
    
    private var knownLocations:[KnownLocation] = []
    
    private var wifiTimer:Timer? = nil
    private var isSSIDKnown:Bool = false
    private var userTrackingEnabled:Bool = true
    private var isUpdatingLocation:Bool = false
    
    init(knownLocations:[KnownLocation]) {
        self.manager = CLLocationManager()
        self.knownLocations = knownLocations
        super.init()
        
        var timerInterval = 60.0
#if DEBUG
        timerInterval = 10.0
#endif
        
        self.wifiTimer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(checkSSIDs), userInfo: nil, repeats: true)
        
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.isSSIDKnown = self.isKnownSSIDCurrently()
        self.updateGeolocationTracking()
    }
    
    func setDelegate(delegate:LocationControllerDelegate?) {
        self.delegate = delegate
    }
    
    func setKnownLocations(knownLocations: [KnownLocation]) {
        self.knownLocations = knownLocations
        self.isSSIDKnown = self.isKnownSSIDCurrently()
        self.updateGeolocationTracking()
    }
    
    func toggleLocationTracking(active: Bool) {
        self.userTrackingEnabled = active
        self.updateGeolocationTracking()
    }

    private func updateGeolocationTracking() {
        let shouldUpdateLocation = self.userTrackingEnabled && !self.isSSIDKnown

        if shouldUpdateLocation && !self.isUpdatingLocation {
            self.manager.startUpdatingLocation()
            self.isUpdatingLocation = true
            print("resumed location tracking")
        } else if !shouldUpdateLocation && self.isUpdatingLocation {
            self.manager.stopUpdatingLocation()
            self.isUpdatingLocation = false
            print("paused location tracking")
        }
    }
    
    private func setNewLocation(location: String, withLocationType locationType: String, withCountry country: String) {
        // Build the location name.
        var fullLocation = ""
        if locationType == "airport" {
            fullLocation = "✈️ " + location + ", " + country
        } else if locationType == "train" {
            fullLocation = "🚄 " + location
        } else if locationType == "home" {
            fullLocation = "🏠 " + location + ", " + country
        } else if locationType == "office" || locationType == "wework" {
            fullLocation = "🏢 " + location + ", " + country
        } else {
            fullLocation = location + ", " + country
        }
        
        print(fullLocation)
        self.delegate?.locationChanged(location: fullLocation)
    }
    
    @objc func checkSSIDs() {
        let wasSSIDKnown = self.isSSIDKnown

        // Get current WifiSSID to add to location identifiers
        let currentSSIDs = currentSSIDs()
        var currentSSID = ""
        if currentSSIDs.count > 0 {
            currentSSID = currentSSIDs[0]
        }
        
        var location = ""
        var locationType = ""
        
        // Check for SSID with priority.
        var foundSSID = false
        if (!currentSSID.isEmpty) {
            for loc in self.knownLocations {
                if let ssid = loc.ssid {
                    if ssid != "" && currentSSID == ssid {
                        location = loc.name
                        locationType = loc.type
                        foundSSID = true
                        break
                    }
                }
            }
        }
        
        if (foundSSID) {
            self.isSSIDKnown = true
            if wasSSIDKnown != self.isSSIDKnown {
                self.updateGeolocationTracking()
            }
            
            // Build the emoji.
            var emoji = ":earth_africa:"
            if locationType == "airport" {
                emoji = ":airplane:"
            } else if locationType == "home" {
                emoji = ":house:"
            } else if locationType == "train" {
                emoji = ":bullettrain_side:"
            } else if locationType == "office" {
                emoji = ":office:"
            } else if locationType == "wework" {
                emoji = ":wework:"
            }
            
            self.setNewLocation(location: location, withLocationType: locationType, withCountry: "")
            self.delegate?.setSlackStatus(statusText: location, withEmoji: emoji, withExpiration: 0)
        } else {
            self.isSSIDKnown = false
            if wasSSIDKnown != self.isSSIDKnown {
                self.updateGeolocationTracking()
            }
        }
    }

    private func isKnownSSIDCurrently() -> Bool {
        let currentSSIDs = currentSSIDs()
        guard let currentSSID = currentSSIDs.first, !currentSSID.isEmpty else {
            return false
        }

        for loc in self.knownLocations {
            if let ssid = loc.ssid, !ssid.isEmpty, currentSSID == ssid {
                return true
            }
        }

        return false
    }
    
    private func currentSSIDs() -> [String] {
        let client = CWWiFiClient.shared()
        return client.interfaces()?.compactMap { interface in
            return interface.ssid()
        } ?? []
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if (locations.count <= 0) {
            print("no locations received")
            return
        }
        
        // If the SSID is a known location, we don't need the geolocation.
        if (self.isSSIDKnown) {
            return
        }
        
        if !self.userTrackingEnabled {
            return
        }
        
        if self.isGeocoding {
            return
        }
        
        // Avoid spamming reverse geocoding on frequent location updates.
        if let lastAttempt = self.lastGeocodeAttempt, Date().timeIntervalSince(lastAttempt) < 20 {
            return
        }
        self.lastGeocodeAttempt = Date()
        
        let location = locations[0]
        self.isGeocoding = true
        self.geocoder.reverseGeocodeLocation(location) { placemarks, error in
            self.isGeocoding = false
            
            if let error = error {
                print("reverse geocode failed with \(error)")
                return
            }
            
            guard let placemark = placemarks?.first else {
                print("reverse geocode returned no placemarks")
                return
            }
            
            var resolvedLocation = ""
            var locationType = ""
            var country = placemark.country ?? ""
            var countryCode = placemark.isoCountryCode ?? ""
            
            // First pass: known locations by postcode prefix.
            if let postalCode = placemark.postalCode, !postalCode.isEmpty {
                for loc in self.knownLocations {
                    if let postcodePrefix = loc.postcodePrefix, !postcodePrefix.isEmpty, postalCode.hasPrefix(postcodePrefix) {
                        resolvedLocation = loc.name
                        locationType = loc.type
                        break
                    }
                }
            }
            
            // Second pass: airport-ish detection.
            if resolvedLocation.isEmpty {
                if let aoi = placemark.areasOfInterest?.first, !aoi.isEmpty, aoi.localizedCaseInsensitiveContains("airport") {
                    resolvedLocation = aoi
                    locationType = "airport"
                } else if let name = placemark.name, name.localizedCaseInsensitiveContains("airport") {
                    resolvedLocation = name
                    locationType = "airport"
                }
            }
            
            // Third pass: city-ish naming.
            if resolvedLocation.isEmpty {
                resolvedLocation = placemark.locality
                    ?? placemark.subAdministrativeArea
                    ?? placemark.administrativeArea
                    ?? placemark.name
                    ?? ""
                
                if !resolvedLocation.isEmpty {
                    locationType = "city"
                }
            }
            
            if country == "United Kingdom" {
                country = "UK"
            }
            
            if resolvedLocation.isEmpty || country.isEmpty {
                print("could not resolve a meaningful location from placemark")
                return
            }
            
            // Build the emoji.
            var emoji = ":earth_africa:"
            if locationType == "airport" {
                emoji = ":airplane:"
            } else if locationType == "home" {
                emoji = ":house:"
            } else if locationType == "train" {
                emoji = ":steam_locomotive:"
            } else if locationType == "office" {
                emoji = ":office:"
            } else if locationType == "wework" {
                emoji = ":wework:"
            } else if !countryCode.isEmpty {
                emoji = ":flag-" + countryCode.lowercased() + ":"
            }
            
            self.setNewLocation(location: resolvedLocation, withLocationType: locationType, withCountry: country)
            self.delegate?.setSlackStatus(statusText: resolvedLocation + ", " + country, withEmoji: emoji, withExpiration: 0)
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("getting location failed with \(error)")
    }

    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        print("monitoring failed with \(error)")
    }

    func locationManager(_ manager: CLLocationManager, didUpdateTo newLocation: CLLocation, from oldLocation: CLLocation) {
        print("didUpdateTo:  \(String(describing: newLocation)) from: \(String(describing: oldLocation))" )
    }

    func locationManager(_ manager: CLLocationManager,
                        didChangeAuthorization status: CLAuthorizationStatus) {
        print("location manager auth status changed to:" )
        switch status {
            case .restricted:
                print("status restricted")
            case .denied:
                print("status denied")
            case .authorized:
                print("status authorized")
            case .notDetermined:
                print("status not yet determined")
            default:
                print("unknown state: \(status)")
        }
    }
}
