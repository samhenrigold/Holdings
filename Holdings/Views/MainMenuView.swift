//
//  MainMenuView.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct MainMenuView: View {
    let onStartGame: (Int) -> Void
    let onResumeGame: (() -> Void)?
    
    @State private var selectedPlayerCount = 4

    var body: some View {
        NavigationStack {
            VStack {
                Spacer()
                
                Text("Holdings")
                    .font(.largeTitle)
                    .bold()

                Text("A game of hotel chain investments")
                    .foregroundStyle(.secondary)

                Spacer()

                VStack {
                    Text("Number of Players")
                        .font(.headline)

                    Picker("Players", selection: $selectedPlayerCount) {
                        ForEach(2...6, id: \.self) { count in
                            Text("\(count) Players").tag(count)
                        }
                    }
                    .pickerStyle(.inline)
                    .frame(maxWidth: 300)
                }

                VStack {
                    Button("New Game") {
                        onStartGame(selectedPlayerCount)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    
                    if let onResumeGame {
                        Button("Resume Game") {
                            onResumeGame()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }

                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    MainMenuView(onStartGame: { _ in }, onResumeGame: nil)
}

#Preview("With Saved Game") {
    MainMenuView(onStartGame: { _ in }, onResumeGame: {})
}
