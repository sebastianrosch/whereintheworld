//
//  KnownLocationDetailView.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 19/11/2022.
//

import Foundation
import SwiftUI

protocol KnownLocationDetailDelegate {
    func saveKnownLocation(knownLocation:KnownLocation)
    func deleteKnownLocation(knownLocation:KnownLocation)
}

struct TypeOption : Hashable {
    let label:String
    let tag:String
}

struct KnownLocationDetailView: View {
    var delegate:KnownLocationDetailDelegate?
    @State var knownLocation: KnownLocation
    @State var typeOptions: [TypeOption] = [
        TypeOption(label:"🏠 Home", tag:"home"),
        TypeOption(label:"🏢 Office", tag:"office"),
        TypeOption(label:"✈️ Airport", tag:"airport"),
        TypeOption(label:"🚄 Train", tag:"train"),
        TypeOption(label:"🏢 WeWork", tag:"wework"),
        TypeOption(label:"Other", tag:"other")]

    var body: some View {
        VStack {
            Form {
                Section(header: Text("KNOWN LOCATION")) {
                    TextField("Name", text: $knownLocation.name)
                    Picker("Type", selection: $knownLocation.type) {
                        ForEach(typeOptions, id: \.self){ option in
                            Text(option.label).tag(option.tag)
                        }
                    }
                    TabView {
                        TextField("Postcode Prefix", text: $knownLocation.postcodePrefixForUI)
                            .tabItem {
                                Label("Geolocation", systemImage: "lock.rectangle")
                                Text("Geolocation")
                            }
                        TextField("SSID", text: $knownLocation.ssidForUI)
                            .tabItem {
                                Label("WiFi", systemImage: "lock.rectangle")
                                Text("WiFi")
                            }
                    }
                }
            }
            
            Button("Delete") {
                deleteKnownLocation()
            }
            
            Button("Save") {
                saveKnownLocation()
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .onAppear(perform: saveKnownLocation)
        .padding()
    }
    
    func deleteKnownLocation(){
        delegate?.deleteKnownLocation(knownLocation: knownLocation)
    }
    
    func saveKnownLocation(){
        if (!(knownLocation.postcodePrefix ?? "").isEmpty && !(knownLocation.ssid ?? "").isEmpty) {
            // If both are set, postcode has priority.
            knownLocation.ssid = ""
        }
        
        delegate?.saveKnownLocation(knownLocation: knownLocation)
    }
}

struct KnownLocationDetail_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            KnownLocationDetailView(knownLocation: KnownLocation(id: 1, name: "Hamburg Office", type: "office"))
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}
