//
//  whereintheworldApp.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 20/09/2022.
//

import SwiftUI

@main
struct whereintheworldApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup("Settings") {
            ConfigView(delegate: appDelegate).handlesExternalEvents(preferring: Set(arrayLiteral: "SettingsWindow"), allowing: Set(arrayLiteral: "SettingsWindow"))
        }.handlesExternalEvents(matching: Set(arrayLiteral: "SettingsWindow"))
        
        Settings {
            ConfigView(delegate: appDelegate)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, StatusItemControllerDelegate, LocationControllerDelegate, ConfigViewDelegate {
    private var statusItemController: StatusItemController!
    private var locationController: LocationController!
    private var slackController: SlackController!

#if DEBUG
    private let delayInSeconds = 5.0
#else
    private let delayInSeconds = 20.0
#endif
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        print("applicationDidFinishLaunching")
        
        let defaults = UserDefaults.standard
        var googleApiKey = ""
        var slackApiKey = ""
        
        if let googleApiKeyVal = defaults.string(forKey: DefaultsKeys.googleApiKey) {
            googleApiKey = googleApiKeyVal
        }
        if let slackApiKeyVal = defaults.string(forKey: DefaultsKeys.slackApiKey) {
            slackApiKey = slackApiKeyVal
        }
        
        if googleApiKey == "" || slackApiKey == "" {
            OpenWindows.SettingsWindow.open()
        }
        
        statusItemController = StatusItemController()
        statusItemController.setDelegate(delegate: self)
        statusItemController.setLocation(location: "Loading...")
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
            self.locationController = LocationController(googleApiKey: googleApiKey)
            self.locationController.setDelegate(delegate: self)
        }
        
        slackController = SlackController(slackApiKey: slackApiKey)
    }
    
    func locationTrackingToggled(active: Bool) {
        locationController?.toggleLocationTracking(active: active)
    }
    
    func setSlackStatus(statusText: String, withEmoji emoji: String, withExpiration expiration: Int = 0) {
        print("setting Slack status to '\(statusText)' with '\(emoji)' for \(expiration) seconds")
        self.slackController.setSlackStatus(statusText: statusText, withEmoji: emoji, withExpiration: expiration)
    }
    
    func locationChanged(location: String) {
        statusItemController?.setLocation(location: location)
    }
    
    func configChanged() {
        loadConfig()
    }
    
    func loadConfig() {
        let defaults = UserDefaults.standard
        var googleApiKey = ""
        var slackApiKey = ""
        
        if let googleApiKeyVal = defaults.string(forKey: DefaultsKeys.googleApiKey) {
            googleApiKey = googleApiKeyVal
        }
        if let slackApiKeyVal = defaults.string(forKey: DefaultsKeys.slackApiKey) {
            slackApiKey = slackApiKeyVal
        }
        
        self.locationController.setGoogleApiKey(googleApiKey: googleApiKey)
        self.slackController.setSlackApiKey(slackApiKey: slackApiKey)
    }
}

enum OpenWindows: String, CaseIterable {
    case SettingsWindow = "SettingsWindow"

    func open(){
        if let url = URL(string: "whereintheworld://\(self.rawValue)") {
            NSWorkspace.shared.open(url)
        }
    }
}
