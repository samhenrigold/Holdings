//
//  AIPlayer.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation

struct AIPlayer {

    enum Difficulty {
        case easy
        case medium
        case hard
    }

    let difficulty: Difficulty

    init(difficulty: Difficulty = .medium) {
        self.difficulty = difficulty
    }

    // MARK: - Decision Making

    func chooseTileToPlay(from tiles: [Tile], engine: GameEngine) -> Tile? {
        let playableTiles = tiles.filter { engine.canPlayTile($0) }
        guard !playableTiles.isEmpty else { return nil }

        switch difficulty {
        case .easy:
            return playableTiles.randomElement()

        case .medium, .hard:
            // evaluateBestTile returns optional but playableTiles is non-empty here
            return evaluateBestTile(from: playableTiles, engine: engine) ?? playableTiles.first
        }
    }

    private func evaluateBestTile(from tiles: [Tile], engine: GameEngine) -> Tile? {
        guard let firstTile = tiles.first else { return nil }
        
        let player = engine.currentPlayer

        var bestTile = firstTile
        var bestScore = -Double.infinity

        for tile in tiles {
            let score = evaluateTilePlacement(tile, player: player, engine: engine)
            if score > bestScore {
                bestScore = score
                bestTile = tile
            }
        }

        return bestTile
    }

    private func evaluateTilePlacement(_ tile: Tile, player: Player, engine: GameEngine) -> Double {
        var score = 0.0
        let result = engine.analyzeTilePlacement(tile)

        switch result {
        case .independent:
            score = 1.0  // Neutral

        case .foundsChain:
            score = 10.0  // Good - gets founder stock
            // Extra value if we have dead stock in any chain
            for chain in HotelChain.allCases where player.stockCount(for: chain) > 0 {
                if !engine.board.activeChains().contains(chain) {
                    score += 20.0  // Reactivating dead stock is very valuable
                }
            }

        case .growsChain(let chain):
            let ourStock = player.stockCount(for: chain)
            if ourStock > 0 {
                score = 5.0 + Double(ourStock) * 0.5  // Good if we own stock
            } else {
                score = 2.0  // Slightly good even without stock
            }

        case .merger(let surviving, let acquired):
            // Evaluate merger based on our stock positions
            for chain in acquired {
                let ourStock = player.stockCount(for: chain)
                let chainSize = engine.board.chainSize(chain)

                // Check if we're majority/minority holder
                let allHoldings = engine.state.players.map { $0.stockCount(for: chain) }
                let maxHolding = allHoldings.max() ?? 0

                if ourStock == maxHolding && ourStock > 0 {
                    // We're majority - merger is great
                    score += 15.0 + Double(chainSize) * 2.0
                } else if ourStock > 0 {
                    // We have some stock - might get minority bonus
                    score += 5.0 + Double(chainSize)
                }
            }

            // Also consider surviving chain
            if player.stockCount(for: surviving) > 0 {
                score += 3.0  // Our surviving stock becomes more valuable
            }

        case .illegal:
            score = -.infinity
        }

        return score
    }

    // MARK: - Chain Selection

    func chooseChainToFound(from options: [HotelChain], player: Player, engine: GameEngine) -> HotelChain {
        // Guard against empty options (should never happen but be safe)
        guard let fallback = options.first else {
            // This shouldn't happen - return any inactive chain
            return HotelChain.allCases.first { !engine.board.activeChains().contains($0) } ?? .sackson
        }
        
        // First priority: chains where we have dead stock
        for chain in options {
            if player.stockCount(for: chain) > 0 {
                return chain
            }
        }

        // Second: prefer cheaper chains early, expensive chains late
        let gameProgress = Double(engine.board.placedTiles.count) / Double(GameRules.totalTiles)

        if gameProgress < 0.3 {
            // Early game - prefer cheaper chains
            return options.min(by: { $0.tier < $1.tier }) ?? fallback
        } else {
            // Late game - prefer expensive chains
            return options.max(by: { $0.tier < $1.tier }) ?? fallback
        }
    }

    // MARK: - Stock Purchase

    func chooseStockPurchases(engine: GameEngine) -> [HotelChain: Int] {
        let player = engine.currentPlayer
        let activeChains = engine.board.activeChains()
        var purchases: [HotelChain: Int] = [:]
        var remainingBudget = player.money
        var remainingPurchases = GameRules.maxStockPurchasesPerTurn

        // Evaluate each chain
        var chainScores: [(chain: HotelChain, score: Double, price: Int)] = []

        for chain in activeChains {
            let price = engine.stockPrice(for: chain)
            guard price <= remainingBudget else { continue }
            guard engine.availableStock(for: chain) > 0 else { continue }

            let score = evaluateStockPurchase(chain: chain, player: player, engine: engine)
            chainScores.append((chain, score, price))
        }

        // Sort by score and buy best options
        chainScores.sort { $0.score > $1.score }

        for (chain, score, price) in chainScores {
            guard score > 0 else { continue }
            guard remainingPurchases > 0 else { break }

            let affordable = remainingBudget / price
            let available = engine.availableStock(for: chain)
            let count = min(min(affordable, available), remainingPurchases)

            if count > 0 {
                purchases[chain] = count
                remainingBudget -= price * count
                remainingPurchases -= count
            }
        }

        return purchases
    }

    private func evaluateStockPurchase(chain: HotelChain, player: Player, engine: GameEngine) -> Double {
        var score = 0.0

        let ourStock = player.stockCount(for: chain)
        let chainSize = engine.board.chainSize(chain)
        let price = engine.stockPrice(for: chain)

        // Find current leader
        let allHoldings = engine.state.players.map { $0.stockCount(for: chain) }
        let maxHolding = allHoldings.max() ?? 0
        let secondMaxHolding = allHoldings.sorted(by: >).dropFirst().first ?? 0

        // Can we become or stay majority?
        let maxBuyable = GameRules.maxStockPurchasesPerTurn
        if ourStock >= maxHolding {
            score += 10.0  // Maintain/gain majority
        } else if ourStock + maxBuyable > maxHolding {
            score += 8.0  // Can overtake
        } else if ourStock > secondMaxHolding || ourStock + maxBuyable > secondMaxHolding {
            score += 5.0  // Can be/become minority
        }

        // Chain size factors
        if chainSize >= GameRules.safeChainSize {
            score += 3.0  // Safe chain - good investment
        } else if chainSize >= 6 {
            score += 1.0  // Medium chain
        }

        // Price efficiency
        score -= Double(price) / 200.0  // Slight penalty for expensive stocks

        // Diversification bonus if we have nothing
        if ourStock == 0 && !engine.board.activeChains().isEmpty {
            score += 2.0
        }

        return score
    }

    // MARK: - Merger Decisions

    func chooseMergerDecision(
        acquiredChain: HotelChain,
        survivingChain: HotelChain,
        chainSize: Int,
        player: Player,
        engine: GameEngine
    ) -> GameEngine.MergerStockDecision {
        let held = player.stockCount(for: acquiredChain)
        let survivingAvailable = engine.availableStock(for: survivingChain)

        // Simple heuristic for medium difficulty:
        // - If surviving chain is safe or large, trade
        // - If we have tiles that could refound the chain, keep some
        // - Otherwise, sell

        let survivingSize = engine.board.chainSize(survivingChain)
        let survivingIsSafe = engine.board.isSafe(survivingChain)

        var sell = 0
        var trade = 0
        var keep = 0

        if survivingIsSafe || survivingSize >= GameRules.safeChainSize / 2 {
            // Prefer trading
            let maxTrade = min(held, survivingAvailable * 2)
            trade = (maxTrade / 2) * 2  // Make it even
            sell = held - trade
        } else {
            // Chain is small, might get re-acquired - sell
            sell = held
        }

        // Check if we might be able to refound (simplified check)
        let hasFoundingTile = player.tiles.contains { tile in
            if case .foundsChain = engine.analyzeTilePlacement(tile) {
                return true
            }
            return false
        }

        if hasFoundingTile && sell > 0 {
            // Keep a few shares for potential refounding
            let keepAmount = min(sell, GameRules.maxStockPurchasesPerTurn)
            keep = keepAmount
            sell -= keepAmount
        }

        return GameEngine.MergerStockDecision(sell: sell, trade: trade, keep: keep)
    }
}
