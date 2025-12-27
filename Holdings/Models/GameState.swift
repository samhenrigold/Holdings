//
//  GameState.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation

struct GameState: Sendable {
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

    static var stocksPerChain: Int { GameRules.stocksPerChain }
    static var startingMoney: Int { GameRules.startingMoney }
    static var tilesPerPlayer: Int { GameRules.tilesPerPlayer }

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

// MARK: - Codable Conformance (nonisolated for cross-actor use)

extension GameState: Codable {
    nonisolated init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        board = try container.decode(Board.self, forKey: .board)
        players = try container.decode([Player].self, forKey: .players)
        currentPlayerIndex = try container.decode(Int.self, forKey: .currentPlayerIndex)
        tileBag = try container.decode([Tile].self, forKey: .tileBag)
        stockMarket = try container.decode([HotelChain: Int].self, forKey: .stockMarket)
        phase = try container.decode(GamePhase.self, forKey: .phase)
        turnPhase = try container.decode(TurnPhase.self, forKey: .turnPhase)
        gameLog = try container.decode([GameLogEntry].self, forKey: .gameLog)
    }
    
    nonisolated func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(board, forKey: .board)
        try container.encode(players, forKey: .players)
        try container.encode(currentPlayerIndex, forKey: .currentPlayerIndex)
        try container.encode(tileBag, forKey: .tileBag)
        try container.encode(stockMarket, forKey: .stockMarket)
        try container.encode(phase, forKey: .phase)
        try container.encode(turnPhase, forKey: .turnPhase)
        try container.encode(gameLog, forKey: .gameLog)
    }
    
    private enum CodingKeys: String, CodingKey {
        case board, players, currentPlayerIndex, tileBag, stockMarket, phase, turnPhase, gameLog
    }
}
