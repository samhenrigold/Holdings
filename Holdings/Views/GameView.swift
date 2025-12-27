//
//  GameView.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct GameView: View {
    @Bindable var engine: GameEngine
    let onExit: () -> Void

    @State private var showingStockPurchase = false
    @State private var showingFoundChain = false
    @State private var showingMergerDecision = false
    @State private var showingMergerAlert = false
    @State private var mergerAlertInfo: MergerAlertInfo?
    @State private var showingGameLog = false
    @State private var showingChainInfo = true
    @State private var pendingStockPurchases: [HotelChain: Int] = [:]
    
    struct MergerAlertInfo {
        let surviving: HotelChain
        let acquired: [HotelChain]
    }

    private let ai = AIPlayer(difficulty: .medium)

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                PlayerInfoBar(engine: engine)
                
                Divider()
                
                BoardView(engine: engine, onTilePlaced: handleTilePlaced)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .navigationTitle("Holdings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Chains", systemImage: "building.2") {
                        showingChainInfo.toggle()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Log", systemImage: "list.bullet") {
                        showingGameLog = true
                    }
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button("Exit", role: .cancel) {
                        onExit()
                    }
                }
            }
            .inspector(isPresented: $showingChainInfo) {
                ChainInfoPanel(engine: engine)
                    .inspectorColumnWidth(min: 200, ideal: 250, max: 300)
            }
            .sheet(isPresented: $showingStockPurchase, onDismiss: {
                // Treat dismissal as skipping stock purchase
                if engine.turnPhase == .buyStocks {
                    engine.skipBuyingStocks()
                }
            }) {
                StockPurchaseSheet(
                    engine: engine,
                    purchases: $pendingStockPurchases,
                    onConfirm: confirmStockPurchase,
                    onSkip: skipStockPurchase
                )
            }
            .sheet(isPresented: $showingFoundChain) {
                if case .foundChain(let options) = engine.turnPhase {
                    FoundChainSheet(
                        options: options,
                        onSelect: handleChainFounded
                    )
                }
            }
            .sheet(isPresented: $showingMergerDecision) {
                if case .handleMergerStock(let context) = engine.turnPhase {
                    MergerDecisionSheet(
                        context: context,
                        engine: engine,
                        onDecision: handleMergerDecision
                    )
                }
            }
            .sheet(isPresented: $showingGameLog) {
                GameLogView(entries: engine.gameLog)
            }
            .alert("Merger!", isPresented: $showingMergerAlert, presenting: mergerAlertInfo) { _ in
                Button("OK") { }
            } message: { info in
                Text("\(info.surviving.displayName) acquires \(info.acquired.map(\.displayName).joined(separator: ", "))")
            }
            .onChange(of: engine.turnPhase) { _, newPhase in
                handlePhaseChange(newPhase)
            }
            .onChange(of: engine.gamePhase) { _, newPhase in
                if newPhase == .gameOver {
                    // Could show game over screen
                }
            }
        }
    }

    // MARK: - Phase Handling

    private func handlePhaseChange(_ phase: TurnPhase) {
        switch phase {
        case .placeTile:
            if !engine.currentPlayer.isHuman {
                performAITurn()
            }

        case .foundChain:
            if engine.currentPlayer.isHuman {
                showingFoundChain = true
            } else {
                performAIFoundChain()
            }

        case .handleMergerStock(let context):
            if let playerIndex = context.currentDecidingPlayerIndex,
                engine.state.players[playerIndex].isHuman
            {
                showingMergerDecision = true
            } else {
                performAIMergerDecision()
            }

        case .buyStocks:
            if engine.currentPlayer.isHuman {
                pendingStockPurchases = [:]
                showingStockPurchase = true
            } else {
                performAIStockPurchase()
            }

        case .endTurn:
            engine.endTurn()

        case .resolveMerger(let context):
            // Show merger alert to all players
            mergerAlertInfo = MergerAlertInfo(surviving: context.survivingChain, acquired: context.acquiredChains)
            showingMergerAlert = true
        }
    }

    // MARK: - Human Actions

    private func handleTilePlaced(_ tile: Tile) {
        engine.playTile(tile)
    }

    private func handleChainFounded(_ chain: HotelChain) {
        showingFoundChain = false
        engine.foundChain(chain)
    }

    private func confirmStockPurchase() {
        showingStockPurchase = false
        engine.buyStocks(pendingStockPurchases)
    }

    private func skipStockPurchase() {
        showingStockPurchase = false
        engine.skipBuyingStocks()
    }

    private func handleMergerDecision(_ decision: GameEngine.MergerStockDecision) {
        showingMergerDecision = false
        engine.handleMergerStockDecision(decision)
    }

    // MARK: - AI Actions
    
    // Delay durations for AI actions (slower for better visibility)
    private let aiTilePlacementDelay: Duration = .seconds(1.2)
    private let aiDecisionDelay: Duration = .seconds(0.8)

    private func performAITurn() {
        Task {
            try? await Task.sleep(for: aiTilePlacementDelay)

            if let tile = ai.chooseTileToPlay(from: engine.currentPlayer.tiles, engine: engine) {
                engine.playTile(tile)
            }
        }
    }

    private func performAIFoundChain() {
        Task {
            try? await Task.sleep(for: aiDecisionDelay)

            if case .foundChain(let options) = engine.turnPhase {
                let choice = ai.chooseChainToFound(from: options, player: engine.currentPlayer, engine: engine)
                engine.foundChain(choice)
            }
        }
    }

    private func performAIStockPurchase() {
        Task {
            try? await Task.sleep(for: aiDecisionDelay)

            let purchases = ai.chooseStockPurchases(engine: engine)
            if purchases.isEmpty {
                engine.skipBuyingStocks()
            } else {
                engine.buyStocks(purchases)
            }
        }
    }

    private func performAIMergerDecision() {
        Task {
            try? await Task.sleep(for: aiDecisionDelay)

            if case .handleMergerStock(let context) = engine.turnPhase,
                let playerIndex = context.currentDecidingPlayerIndex
            {
                let player = engine.state.players[playerIndex]
                let decision = ai.chooseMergerDecision(
                    acquiredChain: context.acquiredChain,
                    survivingChain: context.survivingChain,
                    chainSize: context.chainSize,
                    player: player,
                    engine: engine
                )
                engine.handleMergerStockDecision(decision)
            }
        }
    }
}

#Preview("New Game") {
    GameView(engine: GameEngine(playerCount: 4, humanPlayerIndex: 0), onExit: {})
}

#Preview("Mid-Game") {
    GameView(engine: .previewWithActiveChains(), onExit: {})
}

#Preview("Safe Chain Present") {
    GameView(engine: .previewWithSafeChain(), onExit: {})
}

#Preview("Game Over") {
    GameView(engine: .previewGameOver(), onExit: {})
}
