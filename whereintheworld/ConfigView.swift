//
//  ContentView.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 16/11/2022.
//

import SwiftUI

protocol ConfigViewDelegate {
    func configChanged()
}

struct ConfigView: View {
    private var delegate:ConfigViewDelegate?
    @State private var googleApiKey: String = ""
    @State private var slackApiKey: String = ""
    
    init(delegate:ConfigViewDelegate?) {
        self.delegate = delegate
    }
    
    private func loadSettings() {
        print("loading settings")
        
        let defaults = UserDefaults.standard
        
        if let googleApiKeyVal = defaults.string(forKey: DefaultsKeys.googleApiKey) {
            googleApiKey = googleApiKeyVal
        } else {
            googleApiKey = ""
        }
        
        if let slackApiKeyVal = defaults.string(forKey: DefaultsKeys.slackApiKey) {
            slackApiKey = slackApiKeyVal
        } else {
            slackApiKey = ""
        }
    }
    
    func saveConfig() {
        print("saving settings")
        
        let defaults = UserDefaults.standard
        
        defaults.set(googleApiKey, forKey: DefaultsKeys.googleApiKey)
        defaults.set(slackApiKey, forKey: DefaultsKeys.slackApiKey)
        
        self.delegate?.configChanged()
    }
    
    func clearConfig() {
        print("clearing settings")
        
        googleApiKey = ""
        slackApiKey = ""
        
        saveConfig()
    }

    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundColor(.accentColor)
            Text("where in the world")
            Text("")
            Form {
                SecureInputView("Google Maps API Key", text: $googleApiKey)
                SecureInputView("Slack API Key", text: $slackApiKey)
                Button("Save") {
                    saveConfig()
                }
                Button("Clear") {
                    clearConfig()
                }
            }
        }
        .onAppear(perform: loadSettings)
        .padding()
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView(delegate: nil)
    }
}

struct DefaultsKeys {
    static let googleApiKey = "googleApiKey"
    static let slackApiKey = "slackApiKey"
}

struct SecureInputView: View {
    @Binding private var text: String
    @State private var isSecured: Bool = true
    private var title: String
    
    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            Group {
                if isSecured {
                    SecureField(title, text: $text)
                } else {
                    TextField(title, text: $text)
                }
            }.padding(.trailing, 42)

            Button(action: {
                isSecured.toggle()
            }) {
                Image(systemName: self.isSecured ? "eye.slash" : "eye")
                    .accentColor(.gray)
            }
        }
    }
}
