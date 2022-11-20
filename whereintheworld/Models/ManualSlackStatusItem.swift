//
//  ManualSlackStatusItems.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 19/11/2022.
//

import Foundation

struct ManualSlackStatusItem: Codable, Identifiable {
    let id: Int
    var title: String
    var keyEquivalent: String
    var slackStatusText: String
    var slackEmoji: String
    var slackExpiration: Int
    
    var slackExpirationForUI: String {
        get {
            switch slackExpiration {
            case 0:
                return "never"
            case 900:
                return "15 minutes"
            case 1800:
                return "30 minutes"
            case 3600:
                return "1 hour"
            case 7200:
                return "2 hours"
            case 14400:
                return "4 hours"
            case 28800:
                return "8 hours"
            default:
                return "never"
            }
        }
        set {
            switch newValue {
            case "never":
                slackExpiration = 0
            case "15 minutes":
                slackExpiration = 900
            case "30 minutes":
                slackExpiration = 1800
            case "1 hour":
                slackExpiration = 3600
            case "2 hours":
                slackExpiration = 7200
            case "4 hours":
                slackExpiration = 14400
            case "8 hours":
                slackExpiration = 28800
            default:
                slackExpiration = 0
            }
        }
    }
}
