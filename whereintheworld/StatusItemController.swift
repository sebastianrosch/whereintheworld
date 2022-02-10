//
//  StatusItemController.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 11/02/2020.
//  Copyright © 2022 Sebastian Rosch. All rights reserved.
//

import Cocoa

protocol StatusItemControllerDelegate {
    func locationTrackingToggled(active:Bool)
}

class StatusItemController {
    var delegate:StatusItemControllerDelegate?
    let statusItem: NSStatusItem
    let locationEntry: NSMenuItem
    let toggleButton: NSMenuItem
    let quitButton: NSMenuItem
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
    
    @objc func quit() {
        NSApplication.shared.terminate(self)
    }
}
