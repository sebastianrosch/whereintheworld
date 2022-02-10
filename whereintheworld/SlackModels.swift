//
//  SlackModels.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 10/02/2022.
//  Copyright © 2022 Sebastian Rosch. All rights reserved.
//

import Foundation

struct ProfileWrapper: Codable {
    let profile: Profile?
}

struct Profile: Codable {
    let status_text: String
    let status_emoji: String
    let status_expiration: Int
}
