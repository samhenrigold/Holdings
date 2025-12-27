//
//  MainMenuView.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct MainMenuSheet: View {
    let hasSavedGame: Bool
    let onStartGame: (Int) -> Void
    let onResumeGame: () -> Void
    
    @State private var selectedPlayerCount = 3

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    VStack {
                        Text("Holdings")
                            .font(.largeTitle)
                            .bold()
                        
                        Text("A game of hotel chain investments")
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .listRowBackground(Color.clear)
                }
                
                Section("New Game") {
                    Picker("Number of Players", selection: $selectedPlayerCount) {
                        ForEach(2...6, id: \.self) { count in
                            Text("\(count) Players").tag(count)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                    
                    Button("Start New Game") {
                        onStartGame(selectedPlayerCount)
                    }
                }
                
                if hasSavedGame {
                    Section {
                        Button("Resume Saved Game") {
                            onResumeGame()
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled()
    }
}

#Preview("No Saved Game") {
    MainMenuSheet(hasSavedGame: false, onStartGame: { _ in }, onResumeGame: {})
}

#Preview("With Saved Game") {
    MainMenuSheet(hasSavedGame: true, onStartGame: { _ in }, onResumeGame: {})
}
