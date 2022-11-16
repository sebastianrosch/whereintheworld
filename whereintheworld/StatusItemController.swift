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
        
        self.statusItem.button?.title = "♾️"
        
        // Status
        self.statusMenuItem = NSMenuItem(title: "Loading...", action: nil, keyEquivalent: "")
        
        // Util buttons
        self.toggleButton = NSMenuItem(title: "Pause Tracking", action: #selector(toggleActive), keyEquivalent: "p")
        self.toggleButton.target = self
        
        let settingsButton = NSMenuItem(title: "Settings", action: #selector(openSettings), keyEquivalent: "s")
        settingsButton.target = self
        
        let quitButton = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitButton.target = self
        
        // Set Slack Status
        let manualStatusItems = [
            ManualStatusItem(title: "🍕 Lunch (1h)", keyEquivalent: "l", slackStatusText: "At lunch", slackEmoji: ":pizza:", slackExpiration: 3600),
            ManualStatusItem(title: "🧑‍🤝‍🧑 Offline Meeting (1h)", keyEquivalent: "m", slackStatusText: "In a meeting", slackEmoji: ":people_holding_hands:", slackExpiration: 3600),
            ManualStatusItem(title: "👏 Workshop (2h)", keyEquivalent: "w", slackStatusText: "In a workshop", slackEmoji: ":clap:", slackExpiration: 7200),
            ManualStatusItem(title: "🚄 Train (2h)", keyEquivalent: "t", slackStatusText: "In a train", slackEmoji: ":bullettrain_side:", slackExpiration: 7200),
            ManualStatusItem(title: "🏝️ On vacation", keyEquivalent: "v", slackStatusText: "On vacation", slackEmoji: ":desert_island:", slackExpiration: 0)
        ]
        
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
            self.statusItem.button?.title = "♾️"
        } else {
            self.toggleButton.title = "Continue Tracking"
            self.toggleButton.keyEquivalent = "c"
            self.statusItem.button?.title = "||"
        }
    }
    
    @objc private func setSlackStatus(sender:Any) {
        let menuItem = sender as? NSMenuItem
        let manualStatusItem = menuItem?.representedObject as? ManualStatusItem
        let statusText = manualStatusItem?.slackStatusText ?? ""
        let emoji = manualStatusItem?.slackEmoji ?? ""
        let expiration = manualStatusItem?.slackExpiration ?? 0
        
        self.delegate?.setSlackStatus(statusText: statusText, withEmoji: emoji, withExpiration: expiration)
    }
    
    @objc private func openSettings() {
        OpenWindows.SettingsWindow.open()
    }
    
    @objc private func quit() {
        NSApplication.shared.terminate(self)
    }
    
    @objc func setLocation(location: String) {
        self.statusMenuItem.title = location
    }
}

struct ManualStatusItem: Codable {
    let title: String
    let keyEquivalent: String
    let slackStatusText: String
    let slackEmoji: String
    let slackExpiration: Int
}
