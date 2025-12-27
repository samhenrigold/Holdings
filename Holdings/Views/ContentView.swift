//
//  ContentView.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \SavedGame.updatedAt, order: .reverse) private var savedGames: [SavedGame]
    
    @State private var gameEngine: GameEngine?
    @State private var currentSavedGame: SavedGame?

    private var resumeAction: (() -> Void)? {
        if savedGames.isEmpty {
            return nil
        } else {
            return { resumeGame() }
        }
    }
    
    var body: some View {
        Group {
            if let engine = gameEngine {
                ActiveGameView(
                    engine: engine,
                    savedGame: currentSavedGame,
                    onExit: exitGame
                )
            } else {
                MainMenuView(
                    onStartGame: startNewGame,
                    onResumeGame: resumeAction
                )
            }
        }
    }

    private func startNewGame(playerCount: Int) {
        // Delete any existing saved game
        for game in savedGames {
            modelContext.delete(game)
        }
        
        let engine = GameEngine(playerCount: playerCount, humanPlayerIndex: 0)
        gameEngine = engine
        
        // Create a new saved game
        do {
            let savedGame = try SavedGame(state: engine.state)
            modelContext.insert(savedGame)
            currentSavedGame = savedGame
        } catch {
            print("Failed to create saved game: \(error)")
        }
    }
    
    private func resumeGame() {
        guard let savedGame = savedGames.first else { return }
        
        do {
            let state = try savedGame.loadGameState()
            let engine = GameEngine(state: state)
            gameEngine = engine
            currentSavedGame = savedGame
        } catch {
            print("Failed to load saved game: \(error)")
            // Delete corrupted save
            modelContext.delete(savedGame)
        }
    }
    
    private func exitGame() {
        // Final save before exiting
        if let engine = gameEngine, let savedGame = currentSavedGame {
            do {
                try savedGame.update(with: engine.state)
            } catch {
                print("Failed to save game: \(error)")
            }
        }
        
        // If game is over, delete the save
        if gameEngine?.gamePhase == .gameOver {
            if let savedGame = currentSavedGame {
                modelContext.delete(savedGame)
            }
        }
        
        gameEngine = nil
        currentSavedGame = nil
    }
}

/// Wrapper view that handles auto-saving during gameplay
struct ActiveGameView: View {
    @Bindable var engine: GameEngine
    let savedGame: SavedGame?
    let onExit: () -> Void
    
    var body: some View {
        GameView(engine: engine, onExit: onExit)
            .onChange(of: engine.turnPhase) {
                saveGame()
            }
    }
    
    private func saveGame() {
        guard let savedGame else { return }
        
        do {
            try savedGame.update(with: engine.state)
        } catch {
            print("Failed to save game: \(error)")
        }
    }
}

#Preview("No Saved Game") {
    ContentView()
        .modelContainer(for: SavedGame.self, inMemory: true)
}

#Preview("With Saved Game") {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: SavedGame.self, configurations: config)
    
    // Create a saved game for the preview
    let engine = GameEngine.previewWithActiveChains()
    let savedGame = try! SavedGame(state: engine.state)
    container.mainContext.insert(savedGame)
    
    return ContentView()
        .modelContainer(container)
}

#Preview("Active Game") {
    @Previewable @State var engine = GameEngine.previewWithActiveChains()
    ActiveGameView(engine: engine, savedGame: nil, onExit: {})
}
