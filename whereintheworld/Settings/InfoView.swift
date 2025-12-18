//
//  InfoView.swift
//  whereintheworld
//
//  Created by Sebastian Rosch on 18/12/2025.
//

import SwiftUI

struct InfoView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("About")
                .font(.headline)

            Text("whereintheworld updates your menu bar with your current location and can optionally set your Slack status.")
                .fixedSize(horizontal: false, vertical: true)

            Text("Location priority: Wi‑Fi SSID → known postcode prefix → reverse geocoding.")
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
    }
}

struct InfoView_Previews: PreviewProvider {
    static var previews: some View {
        InfoView()
            .frame(width: 480, height: 240)
    }
}

