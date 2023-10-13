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
    
    private var googleMapsApiKey:String = ""
    private var useOpenStreetMap:Bool = false
    
    private var knownLocations:[KnownLocation] = []
    
    private var wifiTimer:Timer? = nil
    private var isSSIDKnown:Bool = false
    
    init(googleApiKey:String, useOpenStreetMap:Bool, knownLocations:[KnownLocation]) {
        self.manager = CLLocationManager()
        self.googleMapsApiKey = googleApiKey
        self.useOpenStreetMap = useOpenStreetMap
        self.knownLocations = knownLocations
        super.init()
        
        var timerInterval = 60.0
#if DEBUG
        timerInterval = 10.0
#endif
        
        self.wifiTimer = Timer.scheduledTimer(timeInterval: timerInterval, target: self, selector: #selector(checkSSIDs), userInfo: nil, repeats: true)
        
        self.manager.delegate = self
        self.manager.desiredAccuracy = kCLLocationAccuracyBest
        self.manager.startUpdatingLocation()
    }
    
    func setDelegate(delegate:LocationControllerDelegate?) {
        self.delegate = delegate
    }
    
    func setGoogleApiKey(googleApiKey: String){
        self.googleMapsApiKey = googleApiKey
    }
    
    func setUseOpenStreetMap(useOpenStreetMap: Bool) {
        self.useOpenStreetMap = useOpenStreetMap
    }
    
    func toggleLocationTracking(active: Bool) {
        if active {
            self.manager.startUpdatingLocation()
            print("resumed location tracking")
        } else {
            self.manager.stopUpdatingLocation()
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
        }
    }
    
    private func currentSSIDs() -> [String] {
        let client = CWWiFiClient.shared()
        return client.interfaces()?.compactMap { interface in
            return interface.ssid()
        } ?? []
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        Task {
            if (locations.count <= 0) {
                print("no locations received")
                return
            }
            
            // If the SSID is a known location, we don't need the geolocation.
            if (self.isSSIDKnown) {
                return
            }
            
            let location = locations[0]
            let latitude = location.coordinate.latitude
            let longitude = location.coordinate.longitude
            
            if (useOpenStreetMap) {
                print("Fetching address via Nominatim")
                let address = await Nominatim.getAddress(latitude: latitude,longitude: longitude)
                
                if let address = address {
                    print(address)
                    
                    let location = address.address?.town ?? ""
                    var country = address.address?.country ?? ""
                    let countryCode = address.address?.country_code ?? ""
                    let locationType = address.addresstype ?? ""
                    
                    if country == "United Kingdom" {
                        country = "UK"
                    }
                    
                    // Build the emoji.
                    var emoji = ":earth_africa:"
                    if locationType == "airport" {
                        emoji = ":airplane:"
                    } else if locationType == "building" {
                        emoji = ":house:"
                    } else if locationType == "train" {
                        emoji = ":steam_locomotive:"
                    } else if locationType == "office" {
                        emoji = ":office:"
                    } else if locationType == "wework" {
                        emoji = ":wework:"
                    } else if countryCode != "" {
                        emoji = ":flag-" + countryCode.lowercased() + ":"
                    }
                    
                    self.setNewLocation(location: location, withLocationType: locationType, withCountry: country)
                    self.delegate?.setSlackStatus(statusText: location + ", " + country, withEmoji: emoji, withExpiration: 0)
                }
                
                self.delegate?.locationChanged(location: "Error while getting address")
                return
            }
            
            let url = String(format: "https://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&key=%@", latitude, longitude, self.googleMapsApiKey)
            
            var request = URLRequest(url: URL(string: url)!)
            request.httpMethod = "GET"
            request.addValue("application/json", forHTTPHeaderField: "Content-Type")
            let session = URLSession.shared
            let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
                do {
                    if error == nil,
                       let httpResponse = response as? HTTPURLResponse
                    {
                        switch httpResponse.statusCode {
                        case 200:
                            if data == nil {
                                print("error getting data from location request")
                                self.delegate?.locationChanged(location: "Error while getting a response")
                                return
                            }
                            
#if DEBUG
                            if let string = String(bytes: data!, encoding: .utf8) {
                                print(string)
                            } else {
                                print("not a valid UTF-8 sequence")
                            }
#endif
                            
                            break
                        default:
                            return
                        }
                    } else {
                        print("error getting location: \(String(describing: error))")
                        self.delegate?.locationChanged(location: "Error")
                        return
                    }
                    
                    // Validation passed, decode response.
                    let decoder = JSONDecoder()
                    let addressDetails = try? decoder.decode(AddressDetails.self, from: data!)
                    if addressDetails == nil {
                        print("could not parse response")
                        self.delegate?.locationChanged(location: "Error while parsing the response")
                        return
                    }
                    
                    if addressDetails!.errorMessage != nil && !addressDetails!.errorMessage!.isEmpty {
                        print("error response from Google Maps API: \(addressDetails!.errorMessage!)")
                        self.delegate?.locationChanged(location: addressDetails!.errorMessage!)
                        return
                    }
                    
                    if addressDetails!.results == nil {
                        print("no results")
                        self.delegate?.locationChanged(location: "No results for location found")
                        return
                    }
                    
                    var location = ""
                    var country = ""
                    var countryCode = ""
                    var locationType = ""
                    
                    // First pass trying to identify known locations.
                    for address in addressDetails!.results! {
                        for component in address.addressComponents {
                            if component.types.contains("postal_code") {
                                for loc in self.knownLocations {
                                    if let postcodePrefix = loc.postcodePrefix {
                                        if postcodePrefix != "" && component.shortName.starts(with: postcodePrefix) {
                                            location = loc.name
                                            locationType = loc.type
                                            break
                                        }
                                    }
                                }
                            }
                            if component.types.contains("country") {
                                country = component.longName
                            }
                        }
                    }
                    
                    // Second pass trying to identify country and airport.
                    if location == "" || country == "" {
                        for address in addressDetails!.results! {
                            for component in address.addressComponents {
                                if component.types.contains("airport") && !component.types.contains("store") {
                                    location = component.longName
                                    locationType = "airport"
                                }
                                if component.types.contains("country") {
                                    country = component.longName
                                }
                            }
                        }
                    }
                    
                    // Third pass trying to identify country and postal town.
                    if location == "" || country == "" {
                        for address in addressDetails!.results! {
                            for component in address.addressComponents {
                                if component.types.contains("postal_town") {
                                    location = component.longName
                                    locationType = "city"
                                }
                                if component.types.contains("country") {
                                    country = component.longName
                                    countryCode = component.shortName
                                }
                            }
                        }
                    }
                    
                    // Fourth pass trying to identify country and locality.
                    if location == "" || country == "" {
                        for address in addressDetails!.results! {
                            for component in address.addressComponents {
                                if component.types.contains("locality") {
                                    location = component.longName
                                    locationType = "city"
                                }
                                if component.types.contains("country") {
                                    country = component.longName
                                    countryCode = component.shortName
                                }
                            }
                        }
                    }
                    
                    // Fifth pass trying to identify country and locality.
                    if location == "" || country == "" {
                        for address in addressDetails!.results! {
                            for component in address.addressComponents {
                                if component.types.contains("administrative_area_level_3") {
                                    location = component.longName
                                    locationType = "city"
                                }
                                if component.types.contains("country") {
                                    country = component.longName
                                    countryCode = component.shortName
                                }
                            }
                        }
                    }
                    
                    if country == "United Kingdom" {
                        country = "UK"
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
                    } else if countryCode != "" {
                        emoji = ":flag-" + countryCode.lowercased() + ":"
                    }
                    
                    self.setNewLocation(location: location, withLocationType: locationType, withCountry: country)
                    self.delegate?.setSlackStatus(statusText: location + ", " + country, withEmoji: emoji, withExpiration: 0)
                    
                }
            })
            
            task.resume()
        }
    }
    
    func getLocationViaGoogleMaps() {
        
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
