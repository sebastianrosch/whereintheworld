//
//  SlackController.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 16/11/2022.
//

import Foundation


class SlackController {
    private var slackApiKey : String = ""
    private var permanentStatusIcons : [String] = [String]()
    
    init(slackApiKey: String) {
        self.slackApiKey = slackApiKey
    }
    
    func setSlackApiKey(slackApiKey: String){
        self.slackApiKey = slackApiKey
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
                    
                    // If in a permanent status, do not update.
                    if !self.permanentStatusIcons.contains(profile.profile?.status_emoji ?? "") {
                        
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
                            }
                        })
                        
                        setStatusTask.resume()
                    }
                } catch {
                    print("Response failed to decode")
                }
            }
        })
        
        getStatusTask.resume()
    }
}
