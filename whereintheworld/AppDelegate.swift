//
//  AppDelegate.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 11/02/2020.
//  Copyright © 2020 Sebastian Rosch. All rights reserved.
//

import Cocoa
import SwiftUI
import CoreLocation

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, CLLocationManagerDelegate, StatusItemControllerDelegate {
    let statusItemController = StatusItemController(title: "♾️")
    
    let manager = CLLocationManager()
    
    var googleMapsKey : String = ""
    var slackAPIKey : String = ""
    var knownLocations : NSDictionary?
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        // Insert code here to initialize your application
        var keys: NSDictionary?
        if let path = Bundle.main.path(forResource: "Keys", ofType: "plist") {
            keys = NSDictionary(contentsOfFile: path)
        }
        if let dict = keys {
            googleMapsKey = dict["googleMapsKey"] as? String ?? ""
            slackAPIKey = dict["slackAPIKey"] as? String ?? ""
        }
        if let path = Bundle.main.path(forResource: "Locations", ofType: "plist") {
            knownLocations = NSDictionary(contentsOfFile: path)
        }
        
        print(DarkMode.isEnabled)
        statusItemController.delegate = self
        
        let delayInSeconds = 20.0
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
            self.manager.delegate = self
            self.manager.startUpdatingLocation()
        }
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
    }
    
    func locationTrackingToggled(active: Bool) {
        if active {
            self.manager.startUpdatingLocation()
            statusItemController.title = "♾️"
            print("resumed location tracking")
        } else {
            self.manager.stopUpdatingLocation()
            statusItemController.title = "||"
            print("paused location tracking")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if locations.count <= 0 {
            print("no locations received")
            return
        }
        
        let location = locations[0]
        
        let url = String(format: "https://maps.googleapis.com/maps/api/geocode/json?latlng=%f,%f&key=%@", location.coordinate.latitude, location.coordinate.longitude, self.googleMapsKey)
        
        var request = URLRequest(url: URL(string: url)!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let session = URLSession.shared
        let task = session.dataTask(with: request, completionHandler: { data, response, error -> Void in
            do {
                if error != nil {
                    print("error getting location: \(String(describing: error))")
                    return
                }
                if data == nil {
                    print("error getting data from location request")
                    return
                }
                
                let decoder = JSONDecoder()
                let addressDetails = try? decoder.decode(AddressDetails.self, from: data!)
                
                var location = ""
                var country = ""
                var countryCode = ""
                var locationType = ""
                
                if addressDetails?.results == nil {
                    print("no results")
                    return
                }

                // First pass trying to identify known locations.
                if self.knownLocations != nil {
                    for address in addressDetails!.results {
                        for component in address.addressComponents {
                            if component.types.contains("postal_code") {
                                for (_, dict) in self.knownLocations! {
                                    let knownLocation = dict as! NSDictionary
                                    let name = knownLocation["name"] as? String ?? ""
                                    let postcodePrefix = knownLocation["postcodePrefix"] as? String ?? ""
                                    let type = knownLocation["type"] as? String ?? ""
                                
                                    if component.shortName.starts(with: postcodePrefix) {
                                        location = name
                                        locationType = type
                                    }
                                }
                            }
                            if component.types.contains("country") {
                                country = component.longName
                            }
                        }
                    }
                }

                // Second pass trying to identify country and airport.
                if location == "" || country == "" {
                    for address in addressDetails!.results {
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
                    for address in addressDetails!.results {
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
                    for address in addressDetails!.results {
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
                    for address in addressDetails!.results {
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
                
                var fullLocation = ""
                
                if locationType == "airport" {
                    fullLocation = "✈️ " + location + ", " + country
                } else if locationType == "home" {
                    fullLocation = "🏠 " + location + ", " + country
                } else if locationType == "office" {
                    fullLocation = "🏢 " + location + ", " + country
                } else {
                    fullLocation = location + ", " + country
                }
                self.statusItemController.location = fullLocation
                print(fullLocation)
                

                // Update Slack status
                var emoji = ":earth_africa:"
                if locationType == "airport" {
                    emoji = ":airplane:"
                } else if locationType == "home" {
                    emoji = ":house:"
                } else if locationType == "office" {
                    emoji = ":office:"
                } else if countryCode != "" {
                    emoji = ":flag-" + countryCode.lowercased() + ":"
                }
                
                let body = String(format: """
                {
                    "profile": {
                        "status_text": "%@",
                        "status_emoji": "%@",
                        "status_expiration": 0
                    }
                }
                """, location + ", " + country, emoji)
                
                var statusRequest = URLRequest(url: URL(string: "https://slack.com/api/users.profile.set")!)
                statusRequest.httpMethod = "POST"
                statusRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                statusRequest.addValue(String(format: "Bearer %@", self.slackAPIKey), forHTTPHeaderField: "Authorization")
                statusRequest.httpBody = body.data(using: .utf8)

                let session = URLSession.shared
                let task = session.dataTask(with: statusRequest, completionHandler: { data, response, error -> Void in
                    do {
                        if error != nil {
                            print("error updating Slack status: \(String(describing: error))")
                            return
                        }
                        print("updated Slack status")
                    }
                })

                task.resume()
            }
        })

        task.resume()
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
