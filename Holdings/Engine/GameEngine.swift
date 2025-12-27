//
//  GameEngine.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation
import Observation

@MainActor @Observable
final class GameEngine {
    var state: GameState

    var currentPlayer: Player { state.currentPlayer }
    var board: Board { state.board }
    var turnPhase: TurnPhase { state.turnPhase }
    var gamePhase: GamePhase { state.phase }
    var gameLog: [GameLogEntry] { state.gameLog }

    init(playerCount: Int = 4, humanPlayerIndex: Int = 0) {
        self.state = GameState(playerCount: playerCount, humanPlayerIndex: humanPlayerIndex)
    }
    
    /// Initialize from an existing game state (for loading saved games)
    init(state: GameState) {
        self.state = state
    }

    // MARK: - Tile Placement Analysis

    enum TilePlacementResult: Equatable, Sendable {
        case independent
        case foundsChain
        case growsChain(HotelChain)
        case merger(surviving: HotelChain, acquired: [HotelChain])
        case illegal(reason: String)
    }

    func analyzeTilePlacement(_ tile: Tile) -> TilePlacementResult {
        let position = tile.position
        let adjacent = position.adjacentPositions.filter { board.hasTile(at: $0) }

        guard !adjacent.isEmpty else {
            return .independent
        }

        // Find all chains adjacent to this position
        let adjacentChains = Set(adjacent.compactMap { board.chain(at: $0) })

        // Check for illegal merger (two or more safe chains)
        let safeChains = adjacentChains.filter { board.isSafe($0) }
        if safeChains.count >= 2 {
            return .illegal(reason: "Cannot merge two safe hotel chains")
        }

        if adjacentChains.isEmpty {
            // Adjacent to independent tiles only - this founds a chain
            if board.activeChains().count >= GameRules.maxActiveChains {
                return .illegal(reason: "All hotel chains are already active")
            }
            return .foundsChain
        }

        if adjacentChains.count == 1, let chain = adjacentChains.first {
            return .growsChain(chain)
        }

        // Multiple chains - merger
        // The largest chain survives; safe chains cannot be acquired
        let chainsBySize = adjacentChains.sorted { board.chainSize($0) > board.chainSize($1) }
        guard let surviving = chainsBySize.first else {
            // Should never happen since adjacentChains.count > 1
            return .independent
        }
        let acquired = chainsBySize.dropFirst().filter { !board.isSafe($0) }

        return .merger(surviving: surviving, acquired: Array(acquired))
    }

    func canPlayTile(_ tile: Tile) -> Bool {
        guard state.turnPhase == .placeTile else { return false }
        guard currentPlayer.tiles.contains(tile) else { return false }

        if case .illegal = analyzeTilePlacement(tile) {
            return false
        }
        return true
    }

    // MARK: - Actions

    func playTile(_ tile: Tile) {
        guard canPlayTile(tile) else { return }

        let position = tile.position
        let result = analyzeTilePlacement(tile)

        // Place the tile
        state.board.placeTile(at: position)

        // Remove from player's hand
        state.players[state.currentPlayerIndex].tiles.removeAll { $0 == tile }

        log("\(currentPlayer.name) placed tile \(tile.displayName)")

        switch result {
        case .independent:
            state.turnPhase = .buyStocks

        case .foundsChain:
            let availableChains = HotelChain.allCases.filter { !board.activeChains().contains($0) }
            state.turnPhase = .foundChain(availableChains: availableChains)

        case .growsChain(let chain):
            // Add tile to chain and any adjacent independent tiles
            let connected = board.connectedPositions(from: position)
            state.board.assignChain(chain, to: connected)
            log("\(chain.displayName) grew to \(board.chainSize(chain)) tiles")
            state.turnPhase = .buyStocks

        case .merger(let surviving, let acquired):
            handleMergerStart(surviving: surviving, acquired: acquired, triggerPosition: position)

        case .illegal:
            // Shouldn't happen since we check canPlayTile
            break
        }
    }

    func foundChain(_ chain: HotelChain) {
        guard case .foundChain(let available) = state.turnPhase,
              available.contains(chain) else { return }

        // Find all connected tiles and assign to chain
        // The tile we just placed will be at the position we need to find
        // Look for the most recently placed independent tile group
        let independentPositions = board.independentTiles()

        // Find the connected group that includes our just-placed tile
        for position in independentPositions {
            let connected = board.connectedPositions(from: position)
            if connected.count >= 2 && connected.isSubset(of: independentPositions) {
                state.board.assignChain(chain, to: connected)
                break
            }
        }

        // Founder gets one free stock
        if state.stockMarket[chain, default: 0] > 0 {
            state.players[state.currentPlayerIndex].addStock(chain)
            state.stockMarket[chain, default: 0] -= 1
            log("\(currentPlayer.name) founded \(chain.displayName) and received 1 free stock")
        } else {
            // No stock available - founder gets cash equivalent
            let price = PriceChart.stockPrice(chain: chain, size: board.chainSize(chain))
            state.players[state.currentPlayerIndex].money += price
            log("\(currentPlayer.name) founded \(chain.displayName) and received $\(price) (no stock available)")
        }

        state.turnPhase = .buyStocks
    }

    // MARK: - Mergers

    private func handleMergerStart(surviving: HotelChain, acquired: [HotelChain], triggerPosition: Position) {
        log("Merger! \(surviving.displayName) acquires \(acquired.map(\.displayName).joined(separator: ", "))")

        // IMPORTANT: Store chain sizes BEFORE modifying the board
        var chainSizes: [HotelChain: Int] = [:]
        for chain in acquired {
            chainSizes[chain] = board.chainSize(chain)
        }
        
        // Sort by size (largest first) using stored sizes
        let sortedAcquired = acquired.sorted { chainSizes[$0, default: 0] > chainSizes[$1, default: 0] }

        // Now assign all tiles to surviving chain
        let allConnected = board.connectedPositions(from: triggerPosition)
        state.board.assignChain(surviving, to: allConnected)

        // Remove acquired chains from board (but we've already stored their sizes)
        for chain in acquired {
            state.board.removeChain(chain)
        }

        let context = MergerContext(
            survivingChain: surviving,
            acquiredChains: sortedAcquired,
            acquiredChainSizes: chainSizes,
            currentAcquiredIndex: 0
        )
        state.turnPhase = .resolveMerger(context)

        // Process the first acquired chain
        processNextMergerChain()
    }

    private func processNextMergerChain() {
        guard case .resolveMerger(let context) = state.turnPhase,
              let acquiredChain = context.currentAcquiredChain else {
            state.turnPhase = .buyStocks
            return
        }

        // Use the stored chain size (captured before chains were removed)
        let chainSize = context.currentAcquiredChainSize

        // Pay out bonuses
        payMergerBonuses(for: acquiredChain, size: chainSize)

        // Find players with stock in acquired chain (starting with current player, going clockwise)
        var playerOrder: [Int] = []
        for i in 0..<state.players.count {
            let index = (state.currentPlayerIndex + i) % state.players.count
            if state.players[index].stockCount(for: acquiredChain) > 0 {
                playerOrder.append(index)
            }
        }

        if playerOrder.isEmpty {
            // No one has stock, move to next acquired chain
            var updatedContext = context
            updatedContext.currentAcquiredIndex += 1
            state.turnPhase = .resolveMerger(updatedContext)
            processNextMergerChain()
        } else {
            let stockContext = MergerStockContext(
                acquiredChain: acquiredChain,
                survivingChain: context.survivingChain,
                chainSize: chainSize,
                currentPlayerIndex: 0,
                playerOrder: playerOrder,
                mergerContext: context  // Pass merger context for later use
            )
            state.turnPhase = .handleMergerStock(stockContext)
        }
    }

    private func payMergerBonuses(for chain: HotelChain, size: Int) {
        // Find majority and minority shareholders
        let stockholders = state.players.enumerated()
            .map { (index: $0.offset, count: $0.element.stockCount(for: chain)) }
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }

        guard !stockholders.isEmpty else { return }

        let majorityBonus = PriceChart.majorityBonus(chain: chain, size: size)
        let minorityBonus = PriceChart.minorityBonus(chain: chain, size: size)

        let majorityCount = stockholders[0].count
        let majorityHolders = stockholders.filter { $0.count == majorityCount }

        if majorityHolders.count > 1 {
            // Tie for majority - split both bonuses
            let totalBonus = majorityBonus + minorityBonus
            let splitBonus = (totalBonus / majorityHolders.count / GameRules.bonusRoundingIncrement) * GameRules.bonusRoundingIncrement
            for holder in majorityHolders {
                state.players[holder.index].money += splitBonus
                log("\(state.players[holder.index].name) receives $\(splitBonus) (tied majority bonus)")
            }
        } else {
            // Clear majority holder
            state.players[stockholders[0].index].money += majorityBonus
            log("\(state.players[stockholders[0].index].name) receives $\(majorityBonus) (majority bonus)")

            // Find minority holders
            let remaining = stockholders.dropFirst()
            if !remaining.isEmpty {
                let minorityCount = remaining.first!.count
                let minorityHolders = remaining.filter { $0.count == minorityCount }
                let splitBonus = (minorityBonus / minorityHolders.count / GameRules.bonusRoundingIncrement) * GameRules.bonusRoundingIncrement
                for holder in minorityHolders {
                    state.players[holder.index].money += splitBonus
                    log("\(state.players[holder.index].name) receives $\(splitBonus) (minority bonus)")
                }
            }
        }
    }

    struct MergerStockDecision: Sendable {
        var sell: Int
        var trade: Int  // Must be even; player receives trade/2 of surviving chain
        var keep: Int
    }

    func handleMergerStockDecision(_ decision: MergerStockDecision) {
        guard case .handleMergerStock(var context) = state.turnPhase,
              let playerIndex = context.currentDecidingPlayerIndex else { return }

        let chain = context.acquiredChain
        let surviving = context.survivingChain
        let player = state.players[playerIndex]
        let held = player.stockCount(for: chain)

        // Validate decision
        guard decision.sell + decision.trade + decision.keep == held else { return }
        guard decision.trade % 2 == 0 else { return }  // Must trade in pairs

        // Execute decision
        if decision.sell > 0 {
            let price = PriceChart.stockPrice(chain: chain, size: context.chainSize)
            let total = price * decision.sell
            state.players[playerIndex].money += total
            state.players[playerIndex].removeStock(chain, count: decision.sell)
            state.stockMarket[chain, default: 0] += decision.sell
            log("\(player.name) sold \(decision.sell) \(chain.displayName) stock for $\(total)")
        }

        if decision.trade > 0 {
            let received = decision.trade / 2
            let available = state.stockMarket[surviving, default: 0]
            let actualReceived = min(received, available)

            state.players[playerIndex].removeStock(chain, count: decision.trade)
            state.stockMarket[chain, default: 0] += decision.trade
            state.players[playerIndex].addStock(surviving, count: actualReceived)
            state.stockMarket[surviving, default: 0] -= actualReceived
            log("\(player.name) traded \(decision.trade) \(chain.displayName) for \(actualReceived) \(surviving.displayName)")
        }

        if decision.keep > 0 {
            log("\(player.name) kept \(decision.keep) \(chain.displayName) stock")
        }

        // Move to next player
        context.currentPlayerIndex += 1

        if context.currentDecidingPlayerIndex == nil {
            // All players have decided, move to next acquired chain
            var mergerContext = context.mergerContext
            mergerContext.currentAcquiredIndex += 1
            state.turnPhase = .resolveMerger(mergerContext)
            processNextMergerChain()
        } else {
            state.turnPhase = .handleMergerStock(context)
        }
    }

    // MARK: - Stock Purchase

    func stockPrice(for chain: HotelChain) -> Int {
        PriceChart.stockPrice(chain: chain, size: board.chainSize(chain))
    }

    func availableStock(for chain: HotelChain) -> Int {
        state.stockMarket[chain] ?? 0
    }

    func canBuyStock(_ chain: HotelChain) -> Bool {
        guard board.activeChains().contains(chain) else { return false }
        guard availableStock(for: chain) > 0 else { return false }
        guard currentPlayer.money >= stockPrice(for: chain) else { return false }
        return true
    }

    func buyStocks(_ purchases: [HotelChain: Int]) {
        guard state.turnPhase == .buyStocks else { return }

        let totalCount = purchases.values.reduce(0, +)
        guard totalCount <= GameRules.maxStockPurchasesPerTurn else { return }

        var totalCost = 0
        for (chain, count) in purchases {
            guard count > 0 else { continue }
            guard board.activeChains().contains(chain) else { return }
            guard availableStock(for: chain) >= count else { return }
            totalCost += stockPrice(for: chain) * count
        }

        guard currentPlayer.money >= totalCost else { return }

        // Execute purchases
        for (chain, count) in purchases where count > 0 {
            let cost = stockPrice(for: chain) * count
            state.players[state.currentPlayerIndex].money -= cost
            state.players[state.currentPlayerIndex].addStock(chain, count: count)
            state.stockMarket[chain, default: 0] -= count
            log("\(currentPlayer.name) bought \(count) \(chain.displayName) stock for $\(cost)")
        }

        state.turnPhase = .endTurn
    }

    func skipBuyingStocks() {
        guard state.turnPhase == .buyStocks else { return }
        state.turnPhase = .endTurn
    }

    // MARK: - End Turn

    func endTurn() {
        guard state.turnPhase == .endTurn else { return }

        // Draw a tile
        if !state.tileBag.isEmpty {
            let newTile = state.tileBag.removeFirst()
            state.players[state.currentPlayerIndex].tiles.append(newTile)
        }

        // Check for and replace unplayable tiles
        replaceUnplayableTiles()

        // Check end game conditions
        if canDeclareGameOver() {
            // AI will always declare if possible; human gets a choice
            if !currentPlayer.isHuman {
                declareGameOver()
                return
            }
        }

        // Next player
        state.currentPlayerIndex = (state.currentPlayerIndex + 1) % state.players.count
        state.turnPhase = .placeTile
    }

    private func replaceUnplayableTiles() {
        let playerIndex = state.currentPlayerIndex
        var tilesToReplace: [Tile] = []

        for tile in state.players[playerIndex].tiles {
            if case .illegal = analyzeTilePlacement(tile) {
                tilesToReplace.append(tile)
            }
        }

        for tile in tilesToReplace {
            state.players[playerIndex].tiles.removeAll { $0 == tile }
            if !state.tileBag.isEmpty {
                let newTile = state.tileBag.removeFirst()
                state.players[playerIndex].tiles.append(newTile)
            }
            // Unplayable tiles are removed from the game
        }

        if !tilesToReplace.isEmpty {
            log("\(currentPlayer.name) exchanged \(tilesToReplace.count) unplayable tile(s)")
        }
    }

    // MARK: - End Game

    func canDeclareGameOver() -> Bool {
        let chains = board.activeChains()
        guard !chains.isEmpty else { return false }

        // All chains are safe
        let allSafe = chains.allSatisfy { board.isSafe($0) }
        if allSafe { return true }

        // Any chain has reached end game size
        let hasEndGameSize = chains.contains { board.chainSize($0) >= GameRules.endGameChainSize }
        if hasEndGameSize { return true }

        return false
    }

    func declareGameOver() {
        guard canDeclareGameOver() else { return }

        log("Game Over declared by \(currentPlayer.name)")

        // Pay final bonuses for all active chains
        for chain in board.activeChains() {
            let size = board.chainSize(chain)
            payMergerBonuses(for: chain, size: size)
        }

        // Sell all stocks
        for chain in board.activeChains() {
            let price = stockPrice(for: chain)
            for i in 0..<state.players.count {
                let count = state.players[i].stockCount(for: chain)
                if count > 0 {
                    let total = price * count
                    state.players[i].money += total
                    state.players[i].stocks[chain] = 0
                    log("\(state.players[i].name) sold \(count) \(chain.displayName) for $\(total)")
                }
            }
        }

        state.phase = .gameOver

        // Determine winner
        let sorted = state.players.sorted { $0.money > $1.money }
        log("Final standings:")
        for (index, player) in sorted.enumerated() {
            log("\(index + 1). \(player.name): $\(player.money)")
        }
    }

    // MARK: - Helpers

    private func log(_ message: String) {
        state.gameLog.append(GameLogEntry(message: message))
    }
}
