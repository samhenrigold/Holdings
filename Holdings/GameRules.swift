//
//  GameRules.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation

/// Central place for all game rule constants to avoid magic numbers
enum GameRules {
    /// Number of tiles each player starts with
    static let tilesPerPlayer = 6
    
    /// Amount of money each player starts with
    static let startingMoney = 6000
    
    /// Number of stocks available per chain at game start
    static let stocksPerChain = 25
    
    /// Maximum number of hotel chains that can be active
    static let maxActiveChains = HotelChain.allCases.count
    
    /// Maximum number of stocks a player can buy per turn
    static let maxStockPurchasesPerTurn = 3
    
    /// Minimum chain size to be considered "safe" (cannot be acquired)
    static let safeChainSize = 11
    
    /// Chain size that allows the game to be declared over
    static let endGameChainSize = 41
    
    /// Total number of tiles on the board
    static var totalTiles: Int {
        Position.all.count
    }
    
    /// Bonus amounts are rounded down to this increment
    static let bonusRoundingIncrement = 100
}

