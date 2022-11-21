//
//  ManualSlackStatusItems.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 19/11/2022.
//

import Foundation

struct KnownLocation: Codable, Identifiable {
    let id: Int
    var name: String
    var type: String
    var postcodePrefix: String?
    var ssid: String?
    
    var postcodePrefixForUI: String {
        get {
            return postcodePrefix ?? ""
        }
        set {
            postcodePrefix = newValue
        }
    }
    
    var ssidForUI: String {
        get {
            return ssid ?? ""
        }
        set {
            ssid = newValue
        }
    }
}
