//
//  whereintheworldApp.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 14/11/2022.
//

import SwiftUI

@main
struct whereintheworldApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings {
            SettingsView(delegate: appDelegate)
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate, StatusItemControllerDelegate, LocationControllerDelegate, SettingsViewDelegate {
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
        var slackApiKey = ""
        var knownLocations:[KnownLocation] = []
        var manualSlackStatuses:[String] = []
        let permanentSlackStatusIcons:[String] = [":zoom:",":around:"]
        
        if let slackApiKeyVal = defaults.string(forKey: DefaultsKeys.slackApiKey) {
            slackApiKey = slackApiKeyVal
        }
        if let knownLocationsVal = UserDefaults.standard.data(forKey: DefaultsKeys.knownLocationsKey) {
            do {
                // Create JSON Decoder
                let decoder = JSONDecoder()

                // Decode Note
                let knownLocation = try decoder.decode([KnownLocation].self, from: knownLocationsVal)
                knownLocations = knownLocation
            } catch {
                print("Unable to decode known locations (\(error))")
            }
        }
        if let manualSlackStatusesVal = UserDefaults.standard.data(forKey: DefaultsKeys.slackStatusItemsKey) {
            do {
                // Create JSON Decoder
                let decoder = JSONDecoder()

                // Decode Note
                let slackStatus = try decoder.decode([ManualSlackStatusItem].self, from: manualSlackStatusesVal)
                slackStatus.forEach { item in
                    manualSlackStatuses.append(item.slackStatusText)
                }
            } catch {
                print("Unable to decode Slack Status items (\(error))")
            }
        }
        
        if slackApiKey == "" {
            openSettings()
        } else {
            NSApplication.shared.keyWindow?.close()
        }
        
        statusItemController = StatusItemController()
        statusItemController.setDelegate(delegate: self)
        statusItemController.setLocation(location: "Loading...")
        
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + delayInSeconds) {
            self.locationController = LocationController(knownLocations: knownLocations)
            self.locationController.setDelegate(delegate: self)
            self.statusItemController.setLocation(location: "Waiting for location...")
        }
        
        slackController = SlackController(slackApiKey: slackApiKey,
                                          permanentStatusIcons: permanentSlackStatusIcons,
                                          permanentStatuses: manualSlackStatuses)
    }
    
    func openSettings() {
        // Get focus from other apps
        NSApplication.shared.activate(ignoringOtherApps: true)

        let initialContentSize = NSSize(width: 760, height: 420)

        // Create the frame to draw window
        let settings = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: initialContentSize.width, height: initialContentSize.height),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        // Add title
        settings.title = "Settings"

        // Keeps window reference active, we need to use this when using NSHostingView
        settings.isReleasedWhenClosed = false

        // Lets us use SwiftUI views with AppKit
        let hostingController = NSHostingController(rootView: SettingsView(delegate: self))
        settings.contentViewController = hostingController

        // Explicitly enforce a sensible initial size (SwiftUI can otherwise expand to fit content).
        settings.setContentSize(initialContentSize)
        settings.contentMinSize = NSSize(width: 720, height: 380)
        settings.contentMaxSize = NSSize(width: 1000, height: 650)

        // Center and bring forward
        settings.center()
        settings.makeKeyAndOrderFront(nil)
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
    
    func settingsChanged() {
        loadSettings()
    }
    
    func loadSettings() {
        let defaults = UserDefaults.standard
        var slackApiKey = ""
        var knownLocations:[KnownLocation] = []
        
        if let slackApiKeyVal = defaults.string(forKey: DefaultsKeys.slackApiKey) {
            slackApiKey = slackApiKeyVal
        }
        if let knownLocationsVal = defaults.data(forKey: DefaultsKeys.knownLocationsKey) {
            do {
                let decoder = JSONDecoder()
                knownLocations = try decoder.decode([KnownLocation].self, from: knownLocationsVal)
            } catch {
                print("Unable to decode known locations (\(error))")
            }
        }
        
        if self.locationController != nil {
            self.locationController.setKnownLocations(knownLocations: knownLocations)
        }
        if self.slackController != nil {
            self.slackController.setSlackApiKey(slackApiKey: slackApiKey)
        }
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
