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

    @State private var sellCount = 0
    @State private var tradeCount = 0
    
    private enum QuickAction: Equatable {
        case sellAll
        case tradeAll
        case keepAll
        case custom
    }
    
    private var currentAction: QuickAction {
        let maxTrade = (held / 2) * 2
        if sellCount == held && tradeCount == 0 {
            return .sellAll
        } else if tradeCount == maxTrade && sellCount == held - maxTrade && maxTrade > 0 {
            return .tradeAll
        } else if sellCount == 0 && tradeCount == 0 {
            return .keepAll
        }
        return .custom
    }

    private var playerIndex: Int {
        let index = context.currentDecidingPlayerIndex ?? 0
        // Ensure index is valid
        return min(index, engine.state.players.count - 1)
    }

    private var player: Player {
        guard playerIndex >= 0 && playerIndex < engine.state.players.count else {
            // Fallback - should never happen
            return engine.currentPlayer
        }
        return engine.state.players[playerIndex]
    }

    private var held: Int {
        player.stockCount(for: context.acquiredChain)
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
    
    // Safe ranges that never have lowerBound > upperBound
    private var maxSellable: Int {
        max(0, held - tradeCount)
    }
    
    private var maxTradeable: Int {
        max(0, held - sellCount)
    }

    var body: some View {
        NavigationStack {
            VStack {
                // Header with chain colors
                HStack {
                    Circle()
                        .fill(context.acquiredChain.color)
                        .frame(width: 20, height: 20)
                    Text(context.acquiredChain.displayName)
                        .bold()
                    Image(systemName: "arrow.right")
                    Circle()
                        .fill(context.survivingChain.color)
                        .frame(width: 20, height: 20)
                    Text(context.survivingChain.displayName)
                        .bold()
                }
                .font(.title3)
                .padding()
                
                Text("You hold **\(held) shares** of \(context.acquiredChain.displayName) at $\(stockPrice) each")
                    .padding(.bottom)
                
                Form {
                    // Quick action buttons
                    Section("Quick Actions") {
                        quickActionRow(
                            action: .sellAll,
                            title: "Sell All",
                            detail: "+$\(stockPrice * held)",
                            detailColor: .green
                        ) {
                            sellCount = held
                            tradeCount = 0
                        }
                        
                        let maxTrade = (held / 2) * 2  // Round down to even
                        if maxTrade > 0 {
                            quickActionRow(
                                action: .tradeAll,
                                title: "Trade All (\(maxTrade) → \(maxTrade / 2) \(context.survivingChain.displayName))",
                                detail: held - maxTrade > 0 ? "+$\(stockPrice * (held - maxTrade))" : nil,
                                detailColor: .green
                            ) {
                                tradeCount = maxTrade
                                sellCount = held - maxTrade
                            }
                        }
                        
                        quickActionRow(
                            action: .keepAll,
                            title: "Keep All (hold for refounding)",
                            detail: nil,
                            detailColor: nil
                        ) {
                            sellCount = 0
                            tradeCount = 0
                        }
                    }

                    Section("Custom Split") {
                        Stepper("Sell: \(sellCount) → $\(sellValue)", value: $sellCount, in: 0...maxSellable)
                        Stepper("Trade: \(tradeCount) → \(tradeReceived) shares", value: $tradeCount, in: 0...maxTradeable, step: 2)
                        Text("Keep: \(keepCount) shares")
                            .foregroundStyle(.secondary)
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
        }
    }
    
    @ViewBuilder
    private func quickActionRow(
        action: QuickAction,
        title: String,
        detail: String?,
        detailColor: Color?,
        onTap: @escaping () -> Void
    ) -> some View {
        Button {
            onTap()
        } label: {
            HStack {
                if currentAction == action {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundStyle(.blue)
                } else {
                    Image(systemName: "circle")
                        .foregroundStyle(.secondary)
                }
                
                Text(title)
                    .foregroundStyle(.primary)
                
                Spacer()
                
                if let detail, let color = detailColor {
                    Text(detail)
                        .foregroundStyle(color)
                }
            }
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
