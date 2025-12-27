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
    @State private var showingMainMenu = true
    
    /// A placeholder engine used for the background board display
    @State private var placeholderEngine = GameEngine.createPlaceholder()
    
    var body: some View {
        ActiveGameView(
            engine: gameEngine ?? placeholderEngine,
            savedGame: currentSavedGame,
            onExit: exitGame,
            isPlaceholder: gameEngine == nil
        )
        .sheet(isPresented: $showingMainMenu) {
            MainMenuSheet(
                hasSavedGame: !savedGames.isEmpty,
                onStartGame: startNewGame,
                onResumeGame: resumeGame
            )
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
        
        showingMainMenu = false
    }
    
    private func resumeGame() {
        guard let savedGame = savedGames.first else { return }
        
        do {
            let state = try savedGame.loadGameState()
            let engine = GameEngine(state: state)
            gameEngine = engine
            currentSavedGame = savedGame
            showingMainMenu = false
        } catch {
            print("Failed to load saved game: \(error)")
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
        showingMainMenu = true
    }
}

/// Wrapper view that handles auto-saving during gameplay
struct ActiveGameView: View {
    @Bindable var engine: GameEngine
    let savedGame: SavedGame?
    let onExit: () -> Void
    var isPlaceholder: Bool = false
    
    var body: some View {
        GameView(engine: engine, onExit: onExit)
            .disabled(isPlaceholder)
            .onChange(of: engine.turnPhase) {
                if !isPlaceholder {
                    saveGame()
                }
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

#Preview("Main Menu Over Board") {
    ContentView()
        .modelContainer(for: SavedGame.self, inMemory: true)
}

#Preview("Active Game") {
    @Previewable @State var engine = GameEngine.previewWithActiveChains()
    ActiveGameView(engine: engine, savedGame: nil, onExit: {})
}
