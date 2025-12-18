//
//  StatusItemController.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 14/11/2022.
//

import Cocoa
import SwiftUI

protocol StatusItemControllerDelegate {
    func locationTrackingToggled(active:Bool)
    func openSettings()
    func setSlackStatus(statusText: String, withEmoji emoji: String, withExpiration expiration: Int)
}

class StatusItemController {
    private var delegate:StatusItemControllerDelegate?
    
    private let statusItem: NSStatusItem
    private let statusMenuItem: NSMenuItem
    private let toggleButton: NSMenuItem
    
    private var active: Bool
    
    init() {
        self.statusItem =  NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        self.active = true
        
        // Status
        self.statusMenuItem = NSMenuItem(title: "Loading...", action: nil, keyEquivalent: "")
        
        // Util buttons
        self.toggleButton = NSMenuItem(title: "Pause Tracking", action: #selector(toggleActive), keyEquivalent: "p")
        self.toggleButton.target = self
        
        let settingsButton = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "s")
        settingsButton.target = self
        
        let quitButton = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitButton.target = self
        
        var manualStatusItems: [ManualSlackStatusItem] = []
        
        if let data = UserDefaults.standard.data(forKey: DefaultsKeys.slackStatusItemsKey) {
            do {
                // Create JSON Decoder
                let decoder = JSONDecoder()

                // Decode Note
                let statusItems = try decoder.decode([ManualSlackStatusItem].self, from: data)
                manualStatusItems = statusItems
            } catch {
                print("Unable to decode Slack Status menu items (\(error))")
            }
        }
        
        if (manualStatusItems.count <= 0) {
            // Set default Slack Status items.
            let manualStatusItems = [
                ManualSlackStatusItem(id: 1, title: "🍕 Lunch", keyEquivalent: "l", slackStatusText: "Out for lunch", slackEmoji: ":pizza:", slackExpiration: 3600),
                ManualSlackStatusItem(id: 2, title: "🧑‍🤝‍🧑 Offline Meeting", keyEquivalent: "m", slackStatusText: "In a meeting", slackEmoji: ":people_holding_hands:", slackExpiration: 3600),
                ManualSlackStatusItem(id: 3, title: "👏 Workshop", keyEquivalent: "w", slackStatusText: "In a workshop", slackEmoji: ":clap:", slackExpiration: 7200),
                ManualSlackStatusItem(id: 4, title: "🚄 Train", keyEquivalent: "t", slackStatusText: "On a train", slackEmoji: ":bullettrain_side:", slackExpiration: 7200),
                ManualSlackStatusItem(id: 5, title: "🏝️ Vacations", keyEquivalent: "v", slackStatusText: "On vacations", slackEmoji: ":desert_island:", slackExpiration: 0)
            ]
            
            do {
                // Create JSON Encoder
                let encoder = JSONEncoder()
    
                // Encode Note
                let data = try encoder.encode(manualStatusItems)
    
                // Write/Set Data
                UserDefaults.standard.set(data, forKey: DefaultsKeys.slackStatusItemsKey)
    
            } catch {
                print("Unable to encode Slack Status menu items (\(error))")
            }
        }
        
        let setSlackStatusMenuItem = NSMenuItem(title: "Set Slack Status", action: nil, keyEquivalent: "s")
        let setSlackStatusMenu = NSMenu(title: "Set Slack Status")
        
        for manualStatusItem in manualStatusItems {
            let menuItem = NSMenuItem(
                title: manualStatusItem.title,
                action: #selector(setSlackStatus),
                keyEquivalent: manualStatusItem.keyEquivalent)
            menuItem.target = self
            menuItem.representedObject = manualStatusItem
            setSlackStatusMenu.addItem(menuItem)
        }
        
        let statusBarMenu = NSMenu(title: "Menu")
        statusItem.menu = statusBarMenu
        
        statusBarMenu.addItem(self.statusMenuItem)
        statusBarMenu.addItem(.separator())
        statusBarMenu.addItem(setSlackStatusMenuItem)
        statusBarMenu.setSubmenu(setSlackStatusMenu, for: setSlackStatusMenuItem)
        statusBarMenu.addItem(self.toggleButton)
        statusBarMenu.addItem(.separator())
        statusBarMenu.addItem(settingsButton)
        statusBarMenu.addItem(.separator())
        statusBarMenu.addItem(quitButton)

        self.updateStatusBarIcon(active: self.active)
    }
    
    func setDelegate(delegate:StatusItemControllerDelegate?) {
        self.delegate = delegate
    }
    
    @objc private func toggleActive() {
        self.active = !self.active
        
        self.delegate?.locationTrackingToggled(active: self.active)
        
        if self.active {
            self.toggleButton.title = "Pause Tracking"
            self.toggleButton.keyEquivalent = "p"
        } else {
            self.toggleButton.title = "Resume Tracking"
            self.toggleButton.keyEquivalent = "p"
        }

        self.updateStatusBarIcon(active: self.active)
    }
    
    @objc private func setSlackStatus(sender:Any) {
        let menuItem = sender as? NSMenuItem
        let manualStatusItem = menuItem?.representedObject as? ManualSlackStatusItem
        let statusText = manualStatusItem?.slackStatusText ?? ""
        let emoji = manualStatusItem?.slackEmoji ?? ""
        let expiration = manualStatusItem?.slackExpiration ?? 0
        
        self.delegate?.setSlackStatus(statusText: statusText, withEmoji: emoji, withExpiration: expiration)
    }
    
    @objc private func openSettings() {
        self.delegate?.openSettings()
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func setLocation(location: String) {
        self.statusMenuItem.title = location
    }

    private func updateStatusBarIcon(active: Bool) {
        guard let button = self.statusItem.button else { return }

        let symbolName = active ? "location.circle.fill" : "pause.circle.fill"
        let image = NSImage(systemSymbolName: symbolName, accessibilityDescription: nil)
        image?.isTemplate = true

        button.image = image
        button.imagePosition = .imageOnly
        button.title = ""
    }
}
