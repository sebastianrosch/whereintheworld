//
//  SecretsView.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 16/11/2022.
//

import Foundation
import SwiftUI

struct KnownLocationsSettingsView: View, KnownLocationDetailDelegate {
    private var delegate:SettingsViewDelegate?
    @State private var knownLocations: [KnownLocation] = []
    @State private var selection: Int? = nil
    
    var body: some View {
        VStack {
            NavigationView {
                List(knownLocations) { knownLocation in
                    NavigationLink {
                        KnownLocationDetailView(delegate: self, knownLocation: knownLocation)
                    } label: {
                        Text(knownLocation.name)
                    }
                    .tag(knownLocation.id)
                }
                .navigationTitle("Known Location Settings")
            }
            Button("Add") {
                addKnownLocation()
            }
        }
        .onAppear(perform: loadSettings)
        .padding()
    }
    
    init(delegate:SettingsViewDelegate?) {
        self.delegate = delegate
    }
    
    private func loadSettings() {
        print("loading Known Locations settings")
        
        if let data = UserDefaults.standard.data(forKey: DefaultsKeys.knownLocationsKey) {
            do {
                // Create JSON Decoder
                let decoder = JSONDecoder()

                // Decode Note
                let knownLocation = try decoder.decode([KnownLocation].self, from: data)
                knownLocations = knownLocation
            } catch {
                print("Unable to decode known locations (\(error))")
            }
        }
    }
    
    func saveSettings() {
        print("saving Known Location settings")
        
        do {
            // Create JSON Encoder
            let encoder = JSONEncoder()

            // Encode Note
            let data = try encoder.encode(knownLocations)

            // Write/Set Data
            UserDefaults.standard.set(data, forKey: DefaultsKeys.knownLocationsKey)

        } catch {
            print("Unable to encode known location (\(error))")
        }
    }
    
    func addKnownLocation() {
        var maxId = 0
        for (_, element) in knownLocations.enumerated() {
            if (element.id > maxId) {
                maxId = element.id
            }
        }
        
        knownLocations.append(
            KnownLocation(id: maxId+1, name: "Hamburg Office", type: "office", postcodePrefix: "20459"))

        saveSettings()
        
        // Todo: navigate to new entry
    }
    
    func saveKnownLocation(knownLocation: KnownLocation) {
        var elementAtIndex = -1
        for (index, element) in knownLocations.enumerated() {
            if (element.id == knownLocation.id) {
                elementAtIndex = index
            }
        }
        
        if (elementAtIndex >= 0) {
            knownLocations[elementAtIndex] = knownLocation
            saveSettings()
        } else {
            knownLocations.append(knownLocation)
            saveSettings()
        }
    }
    
    func deleteKnownLocation(knownLocation: KnownLocation) {
        var elementAtIndex = -1
        for (index, element) in knownLocations.enumerated() {
            if (element.id == knownLocation.id) {
                elementAtIndex = index
            }
        }
        
        if (elementAtIndex >= 0) {
            knownLocations.remove(at: elementAtIndex)
            saveSettings()
        } else {
            print("couldn't find element with id \(knownLocation.id)")
        }
    }
}
