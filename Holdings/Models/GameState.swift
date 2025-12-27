//
//  GameState.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation

struct GameState: Codable, Sendable {
    var board: Board
    var players: [Player]
    var currentPlayerIndex: Int
    var tileBag: [Tile]
    var stockMarket: [HotelChain: Int]
    var phase: GamePhase
    var turnPhase: TurnPhase
    var gameLog: [GameLogEntry]

    var currentPlayer: Player {
        players[currentPlayerIndex]
    }

    static let stocksPerChain = 25
    static let startingMoney = 6000
    static let tilesPerPlayer = 6

    init(playerCount: Int, humanPlayerIndex: Int = 0) {
        // Create all tiles and shuffle
        var allTiles = Position.all.map { Tile(position: $0) }
        allTiles.shuffle()

        // Create players
        var players: [Player] = []
        for i in 0..<playerCount {
            let isHuman = i == humanPlayerIndex
            let name = isHuman ? "You" : "Computer \(i)"
            players.append(Player(name: name, isHuman: isHuman))
        }

        // Deal tiles to players
        for i in 0..<playerCount {
            let startIndex = i * Self.tilesPerPlayer
            let endIndex = startIndex + Self.tilesPerPlayer
            players[i].tiles = Array(allTiles[startIndex..<endIndex])
        }

        // Remaining tiles go in the bag
        let dealtCount = playerCount * Self.tilesPerPlayer
        self.tileBag = Array(allTiles[dealtCount...])

        self.board = Board()
        self.players = players
        self.currentPlayerIndex = 0
        self.stockMarket = Dictionary(uniqueKeysWithValues: HotelChain.allCases.map { ($0, Self.stocksPerChain) })
        self.phase = .playing
        self.turnPhase = .placeTile
        self.gameLog = []
    }
}

enum GamePhase: Codable, Sendable, Equatable {
    case setup
    case playing
    case gameOver
}

enum TurnPhase: Codable, Sendable, Equatable {
    case placeTile
    case foundChain(availableChains: [HotelChain])
    case resolveMerger(MergerContext)
    case handleMergerStock(MergerStockContext)
    case buyStocks
    case endTurn
}

struct MergerContext: Codable, Sendable, Equatable {
    let survivingChain: HotelChain
    let acquiredChains: [HotelChain]
    let acquiredChainSizes: [HotelChain: Int]  // Store sizes before chains are removed
    var currentAcquiredIndex: Int

    var currentAcquiredChain: HotelChain? {
        guard currentAcquiredIndex < acquiredChains.count else { return nil }
        return acquiredChains[currentAcquiredIndex]
    }
    
    var currentAcquiredChainSize: Int {
        guard let chain = currentAcquiredChain else { return 0 }
        return acquiredChainSizes[chain] ?? 0
    }
}

struct MergerStockContext: Codable, Sendable, Equatable {
    let acquiredChain: HotelChain
    let survivingChain: HotelChain
    let chainSize: Int
    var currentPlayerIndex: Int
    let playerOrder: [Int]  // Indices of players who need to make decisions
    let mergerContext: MergerContext  // Parent context for accessing stored chain sizes

    var currentDecidingPlayerIndex: Int? {
        guard currentPlayerIndex < playerOrder.count else { return nil }
        return playerOrder[currentPlayerIndex]
    }
}

struct GameLogEntry: Identifiable, Codable, Sendable {
    let id: UUID
    let timestamp: Date
    let message: String

    init(message: String) {
        self.id = UUID()
        self.timestamp = Date()
        self.message = message
    }
}
