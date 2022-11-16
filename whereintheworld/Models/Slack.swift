//
//  Slack.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 14/11/2022.
//

import Foundation

// MARK: - ProfileWrapper
struct ProfileWrapper: Codable {
    let profile: Profile?
}

// MARK: - Profile
struct Profile: Codable {
    let status_text: String
    let status_emoji: String
    let status_expiration: Int
}
