//
//  DarkMode.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 11/02/2020.
//  Copyright © 2020 Sebastian Rosch. All rights reserved.
//

import Foundation

enum DarkMode {
    static var isEnabled: Bool {
        let script = """
        tell application "System Events"
            tell appearance preferences
                get properties
                return dark mode
            end tell
        end tell
        """
        
        var error: NSDictionary?
        
        return NSAppleScript(source: script)!.executeAndReturnError(&error).booleanValue
    }
}
