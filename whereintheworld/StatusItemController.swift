//
//  StatusItemController.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 11/02/2020.
//  Copyright © 2022 Sebastian Rosch. All rights reserved.
//

import Cocoa
import SwiftUI

protocol StatusItemControllerDelegate {
    func locationTrackingToggled(active:Bool)
    func setSlackStatus(statusText: String, withEmoji emoji: String, withExpiration expiration: Int)
}

class StatusItemController {
    var delegate:StatusItemControllerDelegate?
    let statusItem: NSStatusItem
    let locationEntry: NSMenuItem
    let toggleButton: NSMenuItem
    let quitButton: NSMenuItem
    
    let statusMenuItem: NSMenuItem
    let statusMenu: NSMenu
    
    var active: Bool
    
    var title: String {
        get {
            return statusItem.button?.title ?? ""
        }
        set {
            statusItem.button?.title = newValue
        }
    }
    
    var location: String {
        get {
            return locationEntry.title
        }
        set {
            locationEntry.title = newValue
        }
    }
    
    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        self.active = true
        
        self.locationEntry = NSMenuItem(title: "Waiting for location...", action: nil, keyEquivalent: "")
        self.toggleButton = NSMenuItem(title: "Pause", action: #selector(toggleActive), keyEquivalent: "p")
        self.quitButton = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        
        self.statusMenuItem = NSMenuItem(title: "Set status", action: nil, keyEquivalent: "s")
        self.statusMenu = NSMenu(title: "Set status")
        let lunchMenuItem = NSMenuItem(title: "🍕 Lunch (1h)", action: #selector(setLunch), keyEquivalent: "l")
        lunchMenuItem.target = self
        statusMenu.addItem(lunchMenuItem)
        let offlineMeetingMenuItem = NSMenuItem(title: "🧑‍🤝‍🧑 Offline Meeting (1h)", action: #selector(setMeeting), keyEquivalent: "m")
        offlineMeetingMenuItem.target = self
        statusMenu.addItem(offlineMeetingMenuItem)
        let workshopMenuItem = NSMenuItem(title: "👏 Workshop (2h)", action: #selector(setWorkshop), keyEquivalent: "w")
        workshopMenuItem.target = self
        statusMenu.addItem(workshopMenuItem)
        let vacationMenuItem = NSMenuItem(title: "🏝 Vacation (♾)", action: #selector(setVacation), keyEquivalent: "v")
        vacationMenuItem.target = self
        statusMenu.addItem(vacationMenuItem)
        
    
        self.toggleButton.target = self
        self.quitButton.target = self
    }
    
    convenience init(title: String) {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.init(statusItem: item)
        statusItem.button?.title = title
        
        let statusBarMenu = NSMenu(title: "Menu")
        statusItem.menu = statusBarMenu
        
        statusBarMenu.addItem(self.locationEntry)
        statusBarMenu.addItem(self.statusMenuItem)
        statusBarMenu.setSubmenu(self.statusMenu, for: self.statusMenuItem)
        statusBarMenu.addItem(self.toggleButton)
        statusBarMenu.addItem(self.quitButton)
    }
    
    @objc func toggleActive() {
        self.active = !self.active
        
        self.delegate?.locationTrackingToggled(active: self.active)
        
        if self.active {
            self.toggleButton.title = "Pause"
            self.toggleButton.keyEquivalent = "p"
        } else {
            self.toggleButton.title = "Continue"
            self.toggleButton.keyEquivalent = "c"
        }
    }
    
    @objc func setLunch() {
        let locationString = "At lunch"
        let emojiString = ":pizza:"
        let emoji = "🍕"
        let expirationSeconds = 3600
        self.delegate?.setSlackStatus(statusText: locationString, withEmoji: emojiString, withExpiration: expirationSeconds)
        self.location = emoji + " " + locationString
        
    }
    @objc func setVacation() {
        let locationString = "On vacation"
        let emojiString = ":desert_island:"
        let emoji = "🏝"
        let expirationSeconds = 0
        self.delegate?.setSlackStatus(statusText: locationString, withEmoji: emojiString, withExpiration: expirationSeconds)
        self.location = emoji + " " + locationString
        
    }
    @objc func setWorkshop() {
        let locationString = "In a workshop"
        let emojiString = ":clap:"
        let emoji = "👏"
        let expirationSeconds = 7200
        self.delegate?.setSlackStatus(statusText: locationString, withEmoji: emojiString, withExpiration: expirationSeconds)
        self.location = emoji + " " + locationString
        
    }
    @objc func setMeeting() {
        let locationString = "In an offline meeting"
        let emojiString = ":people_holding_hands:"
        let emoji = "🧑‍🤝‍🧑"
        let expirationSeconds = 3600
        self.delegate?.setSlackStatus(statusText: locationString, withEmoji: emojiString, withExpiration: expirationSeconds)
        self.location = emoji + " " + locationString
        
    }
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
}
