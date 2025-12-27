//
//  PreviewHelpers.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation

// MARK: - Preview Extensions for GameEngine

extension GameEngine {
    /// Creates a game engine with tiles already placed and chains founded
    static func previewWithActiveChains() -> GameEngine {
        let engine = GameEngine(playerCount: 4, humanPlayerIndex: 0)
        
        // Place tiles to create multiple chains
        // Sackson chain (3 tiles)
        engine.state.board.placeTile(at: Position(column: 2, row: 1))
        engine.state.board.placeTile(at: Position(column: 3, row: 1))
        engine.state.board.placeTile(at: Position(column: 4, row: 1))
        engine.state.board.assignChain(.sackson, to: [
            Position(column: 2, row: 1),
            Position(column: 3, row: 1),
            Position(column: 4, row: 1)
        ])
        
        // American chain (5 tiles)
        engine.state.board.placeTile(at: Position(column: 6, row: 4))
        engine.state.board.placeTile(at: Position(column: 7, row: 4))
        engine.state.board.placeTile(at: Position(column: 8, row: 4))
        engine.state.board.placeTile(at: Position(column: 8, row: 5))
        engine.state.board.placeTile(at: Position(column: 8, row: 6))
        engine.state.board.assignChain(.american, to: [
            Position(column: 6, row: 4),
            Position(column: 7, row: 4),
            Position(column: 8, row: 4),
            Position(column: 8, row: 5),
            Position(column: 8, row: 6)
        ])
        
        // Tower chain (2 tiles) - newly founded
        engine.state.board.placeTile(at: Position(column: 4, row: 8))
        engine.state.board.placeTile(at: Position(column: 5, row: 8))
        engine.state.board.assignChain(.tower, to: [
            Position(column: 4, row: 8),
            Position(column: 5, row: 8)
        ])
        
        // Some independent tiles
        engine.state.board.placeTile(at: Position(column: 9, row: 0))
        engine.state.board.placeTile(at: Position(column: 1, row: 10))
        
        // Give players some stocks
        engine.state.players[0].addStock(.sackson, count: 5)
        engine.state.players[0].addStock(.american, count: 3)
        engine.state.players[1].addStock(.american, count: 4)
        engine.state.players[1].addStock(.tower, count: 2)
        engine.state.players[2].addStock(.sackson, count: 3)
        engine.state.players[3].addStock(.american, count: 2)
        
        // Update stock market
        engine.state.stockMarket[.sackson] = 17
        engine.state.stockMarket[.american] = 16
        engine.state.stockMarket[.tower] = 23
        
        // Adjust money based on "purchases"
        engine.state.players[0].money = 4200
        engine.state.players[1].money = 5100
        engine.state.players[2].money = 5400
        engine.state.players[3].money = 5600
        
        return engine
    }
    
    /// Creates a game engine with a safe chain (11+ tiles)
    static func previewWithSafeChain() -> GameEngine {
        let engine = GameEngine(playerCount: 3, humanPlayerIndex: 0)
        
        // Create a safe Continental chain (12 tiles) - 4 columns x 3 rows
        var continentalPositions: Set<Position> = []
        for col in 1...4 {
            for row in 0...2 {
                let pos = Position(column: col, row: row)
                engine.state.board.placeTile(at: pos)
                continentalPositions.insert(pos)
            }
        }
        engine.state.board.assignChain(.continental, to: continentalPositions)
        
        // Smaller Festival chain (4 tiles)
        let festivalPositions: Set<Position> = [
            Position(column: 7, row: 8),
            Position(column: 8, row: 8),
            Position(column: 7, row: 9),
            Position(column: 8, row: 9)
        ]
        for pos in festivalPositions {
            engine.state.board.placeTile(at: pos)
        }
        engine.state.board.assignChain(.festival, to: festivalPositions)
        
        // Give players stocks
        engine.state.players[0].addStock(.continental, count: 8)
        engine.state.players[0].addStock(.festival, count: 2)
        engine.state.players[1].addStock(.continental, count: 6)
        engine.state.players[2].addStock(.continental, count: 4)
        engine.state.players[2].addStock(.festival, count: 5)
        
        engine.state.stockMarket[.continental] = 7
        engine.state.stockMarket[.festival] = 18
        
        engine.state.players[0].money = 3000
        engine.state.players[1].money = 4500
        engine.state.players[2].money = 2800
        
        return engine
    }
    
    /// Creates a game engine in the stock purchase phase
    static func previewBuyingStocks() -> GameEngine {
        let engine = previewWithActiveChains()
        engine.state.turnPhase = .buyStocks
        return engine
    }
    
    /// Creates a game engine with a pending merger
    static func previewMergerInProgress() -> GameEngine {
        let engine = GameEngine(playerCount: 4, humanPlayerIndex: 0)
        
        // Create two chains about to merge
        // Imperial chain (6 tiles) - will survive
        var imperialPositions: Set<Position> = []
        for col in 3...5 {
            for row in 2...3 {
                let pos = Position(column: col, row: row)
                engine.state.board.placeTile(at: pos)
                imperialPositions.insert(pos)
            }
        }
        engine.state.board.assignChain(.imperial, to: imperialPositions)
        
        // Worldwide chain (4 tiles) - will be acquired
        let worldwidePositions: Set<Position> = [
            Position(column: 6, row: 2),
            Position(column: 7, row: 2),
            Position(column: 6, row: 3),
            Position(column: 7, row: 3)
        ]
        for pos in worldwidePositions {
            engine.state.board.placeTile(at: pos)
        }
        engine.state.board.assignChain(.worldwide, to: worldwidePositions)
        
        // Give players stocks in both chains
        engine.state.players[0].addStock(.worldwide, count: 6)
        engine.state.players[0].addStock(.imperial, count: 2)
        engine.state.players[1].addStock(.worldwide, count: 4)
        engine.state.players[1].addStock(.imperial, count: 5)
        engine.state.players[2].addStock(.worldwide, count: 2)
        engine.state.players[3].addStock(.imperial, count: 3)
        
        engine.state.stockMarket[.worldwide] = 13
        engine.state.stockMarket[.imperial] = 15
        
        return engine
    }
    
    /// Creates a game engine with all 7 chains active
    static func previewAllChainsActive() -> GameEngine {
        let engine = GameEngine(playerCount: 4, humanPlayerIndex: 0)
        
        let chains: [HotelChain] = [.sackson, .worldwide, .festival, .imperial, .american, .continental, .tower]
        
        // Place chains in different rows to fit in 9x12 grid
        let positions: [(col1: Int, col2: Int, row: Int)] = [
            (1, 2, 0), (4, 5, 0), (7, 8, 0),  // Row 0
            (1, 2, 2), (4, 5, 2), (7, 8, 2),  // Row 2
            (4, 5, 4)                          // Row 4
        ]
        
        for (index, chain) in chains.enumerated() {
            let pos = positions[index]
            let pos1 = Position(column: pos.col1, row: pos.row)
            let pos2 = Position(column: pos.col2, row: pos.row)
            engine.state.board.placeTile(at: pos1)
            engine.state.board.placeTile(at: pos2)
            engine.state.board.assignChain(chain, to: [pos1, pos2])
            
            engine.state.players[0].addStock(chain, count: 2)
            engine.state.stockMarket[chain] = 23
        }
        
        engine.state.players[0].money = 2000
        
        return engine
    }
    
    /// Creates a game engine in the founding chain phase
    static func previewFoundingChain() -> GameEngine {
        let engine = GameEngine(playerCount: 4, humanPlayerIndex: 0)
        
        // Place two adjacent tiles to trigger founding
        engine.state.board.placeTile(at: Position(column: 5, row: 5))
        engine.state.board.placeTile(at: Position(column: 6, row: 5))
        
        // Place some other independent tiles
        engine.state.board.placeTile(at: Position(column: 8, row: 2))
        engine.state.board.placeTile(at: Position(column: 3, row: 9))
        
        // Set turn phase to founding
        let availableChains = HotelChain.allCases
        engine.state.turnPhase = .foundChain(availableChains: availableChains)
        
        return engine
    }
    
    /// Creates a game engine in game over state
    static func previewGameOver() -> GameEngine {
        let engine = previewWithSafeChain()
        engine.state.phase = .gameOver
        
        // Simulate final standings
        engine.state.players[0].money = 42300
        engine.state.players[1].money = 38100
        engine.state.players[2].money = 31600
        
        // Clear stocks (sold at end)
        for i in 0..<engine.state.players.count {
            engine.state.players[i].stocks = [:]
        }
        
        // Add some log entries
        engine.state.gameLog.append(GameLogEntry(message: "Game Over declared"))
        engine.state.gameLog.append(GameLogEntry(message: "Final standings:"))
        engine.state.gameLog.append(GameLogEntry(message: "1. You: $42,300"))
        engine.state.gameLog.append(GameLogEntry(message: "2. Computer 1: $38,100"))
        engine.state.gameLog.append(GameLogEntry(message: "3. Computer 2: $31,600"))
        
        return engine
    }
    
    /// Creates a merger stock context for previews
    static func previewMergerStockContext() -> (MergerStockContext, GameEngine) {
        let engine = previewMergerInProgress()
        
        let mergerContext = MergerContext(
            survivingChain: .imperial,
            acquiredChains: [.worldwide],
            acquiredChainSizes: [.worldwide: 4],
            currentAcquiredIndex: 0
        )
        
        let stockContext = MergerStockContext(
            acquiredChain: .worldwide,
            survivingChain: .imperial,
            chainSize: 4,
            currentPlayerIndex: 0,
            playerOrder: [0, 1, 2],
            mergerContext: mergerContext
        )
        
        return (stockContext, engine)
    }
    
    /// Creates a placeholder game engine for the background display (empty board)
    static func createPlaceholder() -> GameEngine {
        GameEngine(playerCount: 4, humanPlayerIndex: 0)
    }
}

