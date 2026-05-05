//
//  SlackController.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 16/11/2022.
//

import Foundation


class SlackController {
    private var slackApiKey:String = ""
    private var permanentStatusIcons:[String] = []
    private var permanentStatuses:[String] = []
    
    init(slackApiKey: String, permanentStatusIcons:[String], permanentStatuses:[String]) {
        self.slackApiKey = slackApiKey
        self.permanentStatusIcons = permanentStatusIcons
        self.permanentStatuses = permanentStatuses
    }
    
    func setSlackApiKey(slackApiKey: String){
        self.slackApiKey = slackApiKey
    }

    private func isStatusUnset(statusText: String, statusEmoji: String) -> Bool {
        return statusText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
            statusEmoji.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func wasStatusSetByThisApp(statusText: String, statusEmoji: String) -> Bool {
        let defaults = UserDefaults.standard
        let lastManagedStatusText = defaults.string(forKey: DefaultsKeys.slackLastManagedStatusText) ?? ""
        let lastManagedStatusEmoji = defaults.string(forKey: DefaultsKeys.slackLastManagedStatusEmoji) ?? ""
        return statusText == lastManagedStatusText && statusEmoji == lastManagedStatusEmoji
    }

    private func saveLastManagedStatus(statusText: String, statusEmoji: String) {
        let defaults = UserDefaults.standard
        defaults.set(statusText, forKey: DefaultsKeys.slackLastManagedStatusText)
        defaults.set(statusEmoji, forKey: DefaultsKeys.slackLastManagedStatusEmoji)
    }
    
    func setSlackStatus(statusText: String, withEmoji emoji: String, withExpiration expiration: Int = 0) {
        // Check the current Slack status before updating it.
        var getStatusRequest = URLRequest(url: URL(string: "https://slack.com/api/users.profile.get")!)
        getStatusRequest.httpMethod = "GET"
        getStatusRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
        getStatusRequest.addValue(String(format: "Bearer %@", self.slackApiKey), forHTTPHeaderField: "Authorization")
        
        let session = URLSession.shared
        let getStatusTask = session.dataTask(with: getStatusRequest, completionHandler: { data, response, error -> Void in
            do {
                if error != nil {
                    print("error getting Slack status: \(String(describing: error))")
                    return
                }
                
                // Read HTTP Response Status code
                if let response = response as? HTTPURLResponse {
                    print("Response HTTP Status code: \(response.statusCode)")
                }
                
                print("retrieved Slack status")
                
                let decoder = JSONDecoder()
                
                do {
                    let profile = try decoder.decode(ProfileWrapper.self, from: data!)
                    let currentStatusText = profile.profile?.status_text ?? ""
                    let currentStatusEmoji = profile.profile?.status_emoji ?? ""
                    let currentStatusIsUnset = self.isStatusUnset(statusText: currentStatusText, statusEmoji: currentStatusEmoji)
                    let currentStatusIsManagedByApp = self.wasStatusSetByThisApp(statusText: currentStatusText, statusEmoji: currentStatusEmoji)
                    
                    // Update only when the current status is empty or was previously set by this app.
                    if (currentStatusIsUnset || currentStatusIsManagedByApp) &&
                        !self.permanentStatusIcons.contains(currentStatusEmoji) &&
                        !self.permanentStatuses.contains(currentStatusText) {
                        
                        var expirationEpoch = expiration
                        if expiration != 0 {
                            expirationEpoch = Int(NSDate().timeIntervalSince1970) + expiration
                        }
                        
                        let newStatus = ProfileWrapper(
                            profile: Profile(
                                status_text: statusText,
                                status_emoji: emoji,
                                status_expiration: expirationEpoch))
                        
                        let jsonEncoder = JSONEncoder()
                        let jsonData = try jsonEncoder.encode(newStatus)
                        let json = String(data: jsonData, encoding: String.Encoding.utf8)
                        
                        var setStatusRequest = URLRequest(url: URL(string: "https://slack.com/api/users.profile.set")!)
                        setStatusRequest.httpMethod = "POST"
                        setStatusRequest.addValue("application/json", forHTTPHeaderField: "Content-Type")
                        setStatusRequest.addValue(String(format: "Bearer %@", self.slackApiKey), forHTTPHeaderField: "Authorization")
                        setStatusRequest.httpBody = json?.data(using: .utf8)
                        
                        let setStatusTask = session.dataTask(with: setStatusRequest, completionHandler: { data, response, error -> Void in
                            do {
                                if error != nil {
                                    print("error updating Slack status: \(String(describing: error))")
                                    return
                                }
                                print("updated Slack status to " + statusText)
                                self.saveLastManagedStatus(statusText: statusText, statusEmoji: emoji)
                            }
                        })
                        
                        setStatusTask.resume()
                    } else {
                        print("skipping Slack status update because current status is user-managed")
                    }
                } catch {
                    print("Response failed to decode")
                }
            }
        })
        
        getStatusTask.resume()
    }
}
