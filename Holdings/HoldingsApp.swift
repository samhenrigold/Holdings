//
//  HoldingsApp.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI
import SwiftData

@main
struct HoldingsApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SavedGame.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(sharedModelContainer)
    }
}
