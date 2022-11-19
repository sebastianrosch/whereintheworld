//
//  SlackStatusRowView.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 19/11/2022.
//

import Foundation
import SwiftUI

protocol SlackStatusDetailDelegate {
    func saveSlackStatus(slackStatus:ManualStatusItem)
    func deleteSlackStatus(slackStatus:ManualStatusItem)
}

struct SlackStatusDetail: View {
    var delegate:SlackStatusDetailDelegate?
    @State var slackStatus: ManualStatusItem
    @State var selectOptions: [String] = ["never","15 minutes","30 minutes","1 hour","2 hours","4 hours","8 hours"]

    var body: some View {
        VStack {
            Form {
                Section(header: Text("MENU ITEM")) {
                    TextField("Name", text: $slackStatus.title)
                    TextField("Key", text: $slackStatus.keyEquivalent)
                }
                Section(header: Text("SLACK STATUS")) {
                    TextField("Status", text: $slackStatus.slackStatusText)
                    TextField("Emoji", text: $slackStatus.slackEmoji)
                    Picker("Expiration", selection: $slackStatus.slackExpirationForUI) {
                        ForEach(selectOptions, id: \.self){
                            Text($0).tag($0)
                        }
                    }
                }
            }
            
            Button("Delete") {
                deleteSlackStatus()
            }
            
            Button("Save") {
                saveSlackStatus()
            }
            .buttonStyle(.borderedProminent)
            .tint(.accentColor)
        }
        .onAppear(perform: saveSlackStatus)
        .padding()
    }
    
    func deleteSlackStatus(){
        delegate?.deleteSlackStatus(slackStatus: slackStatus)
    }
    
    func saveSlackStatus(){
        delegate?.saveSlackStatus(slackStatus: slackStatus)
    }
}

struct SlackStatusDetail_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SlackStatusDetail(slackStatus: ManualStatusItem(id: 1, title: "🍕 Lunch (1h)", keyEquivalent: "l", slackStatusText: "At lunch", slackEmoji: ":pizza:", slackExpiration: 3600))
            SlackStatusDetail(slackStatus: ManualStatusItem(id: 2, title: "🍕 Lunch (1h)", keyEquivalent: "l", slackStatusText: "At lunch", slackEmoji: ":pizza:", slackExpiration: 3600))
        }
        .previewLayout(.fixed(width: 300, height: 70))
    }
}
