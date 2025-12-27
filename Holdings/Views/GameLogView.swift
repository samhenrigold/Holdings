//
//  GameLogView.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct GameLogView: View {
    let entries: [GameLogEntry]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(entries.reversed()) { entry in
                Label {
                    Text(entry.message)
                    Text(entry.timestamp, format: .dateTime.hour().minute().second())
                } icon: {
                    EmptyView()
                }
            }
            .navigationTitle("Game Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview("Few Entries") {
    GameLogView(entries: [
        GameLogEntry(message: "Game started"),
        GameLogEntry(message: "You placed tile 1A")
    ])
}

#Preview("Many Entries") {
    GameLogView(entries: [
        GameLogEntry(message: "Game started"),
        GameLogEntry(message: "You placed tile 1A"),
        GameLogEntry(message: "Computer 1 placed tile 5D"),
        GameLogEntry(message: "Computer 2 placed tile 6D"),
        GameLogEntry(message: "Computer 2 founded Sackson and received 1 free stock"),
        GameLogEntry(message: "Computer 3 placed tile 8F"),
        GameLogEntry(message: "You placed tile 7D"),
        GameLogEntry(message: "Sackson grew to 4 tiles"),
        GameLogEntry(message: "You bought 2 Sackson stock for $400"),
        GameLogEntry(message: "Computer 1 placed tile 3B"),
        GameLogEntry(message: "Computer 2 placed tile 9G"),
        GameLogEntry(message: "Computer 2 founded American and received 1 free stock"),
        GameLogEntry(message: "Merger! American acquires Sackson"),
        GameLogEntry(message: "You receives $3000 (majority bonus)"),
        GameLogEntry(message: "Computer 2 receives $1500 (minority bonus)"),
        GameLogEntry(message: "You sold 5 Sackson stock for $1000")
    ])
}

#Preview("Game Over") {
    GameLogView(entries: [
        GameLogEntry(message: "Game Over declared by You"),
        GameLogEntry(message: "You receives $6000 (majority bonus)"),
        GameLogEntry(message: "Computer 1 receives $3000 (minority bonus)"),
        GameLogEntry(message: "You sold 8 Continental for $5600"),
        GameLogEntry(message: "Computer 1 sold 6 Continental for $4200"),
        GameLogEntry(message: "Computer 2 sold 4 Continental for $2800"),
        GameLogEntry(message: "3. Computer 2: $31,600"),
        GameLogEntry(message: "2. Computer 1: $38,100"),
        GameLogEntry(message: "1. You: $42,300"),
        GameLogEntry(message: "Final standings:"),
    ])
}
