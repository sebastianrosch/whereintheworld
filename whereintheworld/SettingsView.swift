//
//  ContentView.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 16/11/2022.
//

import SwiftUI

protocol SettingsViewDelegate {
    func settingsChanged()
}

struct SettingsView: View {
    private var delegate:SettingsViewDelegate?
    @State private var googleApiKey: String = ""
    @State private var slackApiKey: String = ""
    
    init(delegate:SettingsViewDelegate?) {
        self.delegate = delegate
    }

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("where in the world")
            Text("")
            TabView {
                SecretsView(delegate: self.delegate)
                    .tabItem {
                        Label("Credentials", systemImage: "lock.rectangle")
                        Text("Credentials")
                    }
                SlackStatusView(delegate: self.delegate)
                    .tabItem {
                        Label("Slack Status", systemImage: "lock.circle")
                        Text("Slack Status")
                    }
            }
        }
    }
}

struct SettingsView_Previews: PreviewProvider {
    static var previews: some View {
        SettingsView(delegate: nil)
    }
}
