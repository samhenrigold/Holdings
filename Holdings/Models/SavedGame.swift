//
//  SavedGame.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation
import SwiftData

@Model
final class SavedGame {
    var createdAt: Date
    var updatedAt: Date
    
    /// The encoded GameState data
    var gameStateData: Data
    
    /// Quick access properties for display
    var playerCount: Int
    var turnNumber: Int
    var humanMoney: Int
    
    @MainActor
    init(state: GameState) throws {
        let encoder = JSONEncoder()
        self.gameStateData = try encoder.encode(state)
        
        self.createdAt = Date()
        self.updatedAt = Date()
        self.playerCount = state.players.count
        self.turnNumber = state.gameLog.count
        self.humanMoney = state.players.first(where: \.isHuman)?.money ?? 0
    }
    
    @MainActor
    func loadGameState() throws -> GameState {
        let decoder = JSONDecoder()
        return try decoder.decode(GameState.self, from: gameStateData)
    }
    
    @MainActor
    func update(with state: GameState) throws {
        let encoder = JSONEncoder()
        self.gameStateData = try encoder.encode(state)
        self.updatedAt = Date()
        self.turnNumber = state.gameLog.count
        self.humanMoney = state.players.first(where: \.isHuman)?.money ?? 0
    }
}

