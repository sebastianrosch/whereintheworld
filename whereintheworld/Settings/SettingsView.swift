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
    @State private var slackApiKey: String = ""
    
    init(delegate:SettingsViewDelegate?) {
        self.delegate = delegate
    }

    var body: some View {
        VStack {
            Image(systemName: "location.circle.fill")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("where in the world")
            Text("")
            TabView {
                InfoView()
                    .tabItem {
                        Label("Info", systemImage: "info.circle")
                        Text("Info")
                    }
                SlackStatusSettingsView(delegate: self.delegate)
                    .tabItem {
                        Label("Slack Status", systemImage: "lock.circle")
                        Text("Slack Status")
                    }
                KnownLocationsSettingsView(delegate: self.delegate)
                    .tabItem {
                        Label("Known Locations", systemImage: "lock.circle")
                        Text("Known Locations")
                    }
                SecretsView(delegate: self.delegate)
                    .tabItem {
                        Label("Settings", systemImage: "gearshape")
                        Text("Settings")
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
