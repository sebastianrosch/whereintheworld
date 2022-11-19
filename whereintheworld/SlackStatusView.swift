//
//  SecretsView.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 16/11/2022.
//

import Foundation
import SwiftUI

struct SlackStatusView: View, SlackStatusDetailDelegate {
    private var delegate:SettingsViewDelegate?
    @State private var googleApiKey: String = ""
    @State private var slackApiKey: String = ""
    @State private var manualStatusItems: [ManualStatusItem] = []
    @State private var selection: Int? = nil
    
    var body: some View {
        VStack {
            NavigationView {
                List(manualStatusItems) { slackStatusItem in
                    NavigationLink {
                        SlackStatusDetail(delegate: self, slackStatus: slackStatusItem)
                    } label: {
                        Text("\(slackStatusItem.title) (\(slackStatusItem.slackExpirationForUI))")
                    }
                    .tag(slackStatusItem.id)
                }
                .navigationTitle("Slack Status Settings")
            }
            Button("Add") {
                addSlackStatus()
            }
        }
        .onAppear(perform: loadSettings)
        .padding()
    }
    
    init(delegate:SettingsViewDelegate?) {
        self.delegate = delegate
    }
    
    private func loadSettings() {
        print("loading Slack Status settings")
        
        if let data = UserDefaults.standard.data(forKey: DefaultsKeys.slackStatusItemsKey) {
            do {
                // Create JSON Decoder
                let decoder = JSONDecoder()

                // Decode Note
                let statusItems = try decoder.decode([ManualStatusItem].self, from: data)
                manualStatusItems = statusItems
            } catch {
                print("Unable to decode Slack Status menu items (\(error))")
            }
        }
    }
    
    func saveSettings() {
        print("saving Slack Status settings")
        
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
    
    func addSlackStatus() {
        var maxId = 0
        for (_, element) in manualStatusItems.enumerated() {
            if (element.id > maxId) {
                maxId = element.id
            }
        }
        
        manualStatusItems.append(
            ManualStatusItem(id: maxId+1, title: "🍕 Lunch", keyEquivalent: "l", slackStatusText: "At lunch", slackEmoji: ":pizza:", slackExpiration: 3600))
        
        // Todo: navigate to new entry
    }
    
    func saveSlackStatus(slackStatus: ManualStatusItem) {
        var elementAtIndex = -1
        for (index, element) in manualStatusItems.enumerated() {
            if (element.id == slackStatus.id) {
                elementAtIndex = index
            }
        }
        
        if (elementAtIndex >= 0) {
            manualStatusItems[elementAtIndex] = slackStatus
            saveSettings()
        } else {
            print("couldn't find element with id \(slackStatus.id)")
        }
    }
    
    func deleteSlackStatus(slackStatus: ManualStatusItem) {
        var elementAtIndex = -1
        for (index, element) in manualStatusItems.enumerated() {
            if (element.id == slackStatus.id) {
                elementAtIndex = index
            }
        }
        
        if (elementAtIndex >= 0) {
            manualStatusItems.remove(at: elementAtIndex)
            saveSettings()
        } else {
            print("couldn't find element with id \(slackStatus.id)")
        }
    }
}
