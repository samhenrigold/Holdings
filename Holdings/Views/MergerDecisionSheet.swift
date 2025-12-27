//
//  MergerDecisionSheet.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct MergerDecisionSheet: View {
    let context: MergerStockContext
    let engine: GameEngine
    let onDecision: (GameEngine.MergerStockDecision) -> Void

    @State private var selectedAction: QuickAction = .keepAll
    @State private var sellCount = 0
    @State private var tradeCount = 0
    
    private enum QuickAction: String, CaseIterable, Identifiable {
        case sellAll = "Sell All"
        case tradeAll = "Trade All"
        case keepAll = "Keep All"
        case custom = "Custom"
        
        var id: String { rawValue }
    }

    private var playerIndex: Int {
        let index = context.currentDecidingPlayerIndex ?? 0
        return min(index, engine.state.players.count - 1)
    }

    private var player: Player {
        guard playerIndex >= 0 && playerIndex < engine.state.players.count else {
            return engine.currentPlayer
        }
        return engine.state.players[playerIndex]
    }

    private var held: Int {
        player.stockCount(for: context.acquiredChain)
    }
    
    private var survivingStockAvailable: Int {
        engine.availableStock(for: context.survivingChain)
    }
    
    private var maxTrade: Int {
        let evenHeld = (held / 2) * 2  // Round down to even
        let maxByAvailability = survivingStockAvailable * 2  // Can only trade if bank has stock
        return min(evenHeld, maxByAvailability)
    }
    
    private var tradeIsLimited: Bool {
        survivingStockAvailable < held / 2
    }

    private var keepCount: Int {
        max(0, held - sellCount - tradeCount)
    }
    
    private var stockPrice: Int {
        PriceChart.stockPrice(chain: context.acquiredChain, size: context.chainSize)
    }

    private var sellValue: Int {
        stockPrice * sellCount
    }

    private var tradeReceived: Int {
        tradeCount / 2
    }

    private var isValid: Bool {
        sellCount >= 0 && tradeCount >= 0 && sellCount + tradeCount <= held && tradeCount % 2 == 0
    }
    
    private var maxSellable: Int {
        max(0, held - tradeCount)
    }
    
    private var maxTradeable: Int {
        max(0, held - sellCount)
    }
    
    private var availableActions: [QuickAction] {
        var actions: [QuickAction] = [.sellAll]
        if maxTrade > 0 {
            actions.append(.tradeAll)
        }
        actions.append(contentsOf: [.keepAll, .custom])
        return actions
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Your Shares") {
                        Text("\(held) @ \(Text(currency: stockPrice))")
                    }
                    
                    LabeledContent("Total Value") {
                        Text(currency: stockPrice * held)
                            .bold()
                    }
                } header: {
                    VStack {
                        HStack {
                            ChainShape(chain: context.acquiredChain)
                            Image(systemName: "arrow.forward")
                            ChainShape(chain: context.survivingChain)
                        }
                        Text("\(context.acquiredChain.displayName) acquired by \(context.survivingChain.displayName)")
                    }
                    .frame(maxWidth: .infinity)
                }

                Section {
                    Picker("Action", selection: $selectedAction) {
                        ForEach(availableActions) { action in
                            Text(action.rawValue).tag(action)
                        }
                    }
                    .pickerStyle(.inline)
                    .labelsHidden()
                }
                
                if selectedAction == .custom {
                    Section("Custom Split") {
                        LabeledContent("Sell") {
                            Stepper("\(sellCount) → \(Text(currency: sellValue))", value: $sellCount, in: 0...maxSellable)
                                .monospacedDigit()
                        }
                        
                        LabeledContent("Trade") {
                            Stepper("\(tradeCount) → \(tradeReceived) shares", value: $tradeCount, in: 0...maxTradeable, step: 2)
                                .monospacedDigit()
                        }
                        
                        LabeledContent("Keep") {
                            Text("\(keepCount) shares")
                                .foregroundStyle(.secondary)
                        }
                    }
                } else {
                    Section("Result") {
                        switch selectedAction {
                        case .sellAll:
                            LabeledContent("You Receive") {
                                Text(currency: stockPrice * held)
                                    .foregroundStyle(.green)
                                    .bold()
                            }
                        case .tradeAll:
                            LabeledContent("You Receive") {
                                Text("\(maxTrade / 2) \(context.survivingChain.displayName) shares")
                            }
                            if held - maxTrade > 0 {
                                LabeledContent("Plus Cash") {
                                    Text(currency: stockPrice * (held - maxTrade))
                                        .foregroundStyle(.green)
                                }
                            }
                            if tradeIsLimited {
                                Label("Limited by bank stock (\(survivingStockAvailable) available)", systemImage: "exclamationmark.triangle")
                                    .foregroundStyle(.orange)
                            }
                        case .keepAll:
                            LabeledContent("Shares Kept") {
                                Text("\(held) \(context.acquiredChain.displayName)")
                            }
                            Text("Hold for potential refounding of \(context.acquiredChain.displayName)")
                                .foregroundStyle(.secondary)
                        case .custom:
                            EmptyView()
                        }
                    }
                }
            }
            .navigationTitle("Merger")
            .navigationBarTitleDisplayMode(.inline)
            .interactiveDismissDisabled()
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") {
                        onDecision(GameEngine.MergerStockDecision(
                            sell: sellCount,
                            trade: tradeCount,
                            keep: keepCount
                        ))
                    }
                    .disabled(!isValid)
                }
            }
            .onChange(of: selectedAction) { _, newAction in
                applyQuickAction(newAction)
            }
            .onAppear {
                applyQuickAction(selectedAction)
            }
        }
    }
    
    private func applyQuickAction(_ action: QuickAction) {
        switch action {
        case .sellAll:
            sellCount = held
            tradeCount = 0
        case .tradeAll:
            tradeCount = maxTrade
            sellCount = held - maxTrade
        case .keepAll:
            sellCount = 0
            tradeCount = 0
        case .custom:
            break
        }
    }
}

#Preview("Standard Merger") {
    let (context, engine) = GameEngine.previewMergerStockContext()
    MergerDecisionSheet(
        context: context,
        engine: engine,
        onDecision: { _ in }
    )
}

#Preview("Large Stock Holding") {
    let mergerContext = MergerContext(
        survivingChain: .continental,
        acquiredChains: [.sackson],
        acquiredChainSizes: [.sackson: 10],
        currentAcquiredIndex: 0
    )
    let context = MergerStockContext(
        acquiredChain: .sackson,
        survivingChain: .continental,
        chainSize: 10,
        currentPlayerIndex: 0,
        playerOrder: [0],
        mergerContext: mergerContext
    )
    
    let engine = GameEngine(playerCount: 4, humanPlayerIndex: 0)
    engine.state.players[0].addStock(.sackson, count: 12)
    
    return MergerDecisionSheet(
        context: context,
        engine: engine,
        onDecision: { _ in }
    )
}

#Preview("Small Stock Holding") {
    let mergerContext = MergerContext(
        survivingChain: .tower,
        acquiredChains: [.festival],
        acquiredChainSizes: [.festival: 5],
        currentAcquiredIndex: 0
    )
    let context = MergerStockContext(
        acquiredChain: .festival,
        survivingChain: .tower,
        chainSize: 5,
        currentPlayerIndex: 0,
        playerOrder: [0],
        mergerContext: mergerContext
    )
    
    let engine = GameEngine(playerCount: 3, humanPlayerIndex: 0)
    engine.state.players[0].addStock(.festival, count: 2)
    
    return MergerDecisionSheet(
        context: context,
        engine: engine,
        onDecision: { _ in }
    )
}
