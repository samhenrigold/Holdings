//
//  StockPurchaseSheet.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct StockPurchaseSheet: View {
    let engine: GameEngine
    @Binding var purchases: [HotelChain: Int]
    let onConfirm: () -> Void
    let onSkip: () -> Void

    // Capture sorted chains once when sheet appears to prevent re-ordering
    @State private var sortedChains: [HotelChain] = []

    private var totalCost: Int {
        purchases.reduce(0) { total, entry in
            total + engine.stockPrice(for: entry.key) * entry.value
        }
    }

    private var totalCount: Int {
        purchases.values.reduce(0, +)
    }

    private var canAfford: Bool {
        totalCost <= engine.currentPlayer.money
    }

    private var remainingAfterPurchase: Int {
        engine.currentPlayer.money - totalCost
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    LabeledContent("Your Cash") {
                        Text(currency: engine.currentPlayer.money)
                    }

                    LabeledContent("Purchase Total") {
                        Text(currency: -totalCost)
                    }

                    LabeledContent("After Purchase") {
                        Text(currency: remainingAfterPurchase)
                            .foregroundStyle(canAfford ? AnyShapeStyle(.primary) : AnyShapeStyle(.red))
                            .bold()
                    }
                }
                .contentTransition(.numericText(countsDown: true))
                .animation(.default, value: remainingAfterPurchase)

                Section {
                    LabeledContent("Stocks Selected") {
                        Text("\(totalCount) of \(GameRules.maxStockPurchasesPerTurn)")
                            .foregroundStyle(totalCount == GameRules.maxStockPurchasesPerTurn ? .orange : .secondary)
                    }
                } footer: {
                    Text("You may buy up to \(GameRules.maxStockPurchasesPerTurn) stocks per turn from any active hotel chains.")
                }

                Section("Active Hotel Chains") {
                    ForEach(sortedChains) { chain in
                        StockPurchaseRow(
                            chain: chain,
                            chainSize: engine.board.chainSize(chain),
                            price: engine.stockPrice(for: chain),
                            inBank: engine.availableStock(for: chain),
                            youOwn: engine.currentPlayer.stockCount(for: chain),
                            buying: purchases[chain] ?? 0,
                            maxCanBuy: GameRules.maxStockPurchasesPerTurn - (totalCount - (purchases[chain] ?? 0)),
                            onCountChange: { purchases[chain] = $0 }
                        )
                    }
                }
            }
            .navigationTitle("Buy Stocks")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Skip", role: .cancel) { onSkip() }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Buy") { onConfirm() }
                        .disabled(!canAfford || totalCount == 0)
                }
            }
            .onAppear {
                // Sort chains once and keep stable order
                sortedChains = engine.board.activeChains().sorted { $0.rawValue < $1.rawValue }
            }
        }
    }
}

struct StockPurchaseRow: View {
    let chain: HotelChain
    let chainSize: Int
    let price: Int
    let inBank: Int
    let youOwn: Int
    let buying: Int
    let maxCanBuy: Int
    let onCountChange: (Int) -> Void

    private var maxAllowed: Int {
        max(0, min(inBank, maxCanBuy))
    }

    var body: some View {
        LabeledContent {
            Text(currency: price)
            Stepper(
                "Buy: \(buying)",
                value: Binding(
                    get: { buying },
                    set: { newValue in
                        let clamped = max(0, min(newValue, maxAllowed))
                        onCountChange(clamped)
                    }
                ),
                in: 0...maxAllowed
            )
            .fixedSize()
            .monospacedDigit()
        } label: {
            Label {
                Text(chain.displayName)
                Text("\(inBank) in bank · You own \(youOwn)")
            } icon: {
                ChainShape(chain: chain)
            }
        }
    }
}

#Preview("No Active Chains") {
    @Previewable @State var purchases: [HotelChain: Int] = [:]
    StockPurchaseSheet(
        engine: GameEngine(playerCount: 4, humanPlayerIndex: 0),
        purchases: $purchases,
        onConfirm: {},
        onSkip: {}
    )
}

#Preview("Multiple Active Chains") {
    @Previewable @State var purchases: [HotelChain: Int] = [:]
    StockPurchaseSheet(
        engine: .previewBuyingStocks(),
        purchases: $purchases,
        onConfirm: {},
        onSkip: {}
    )
}

#Preview("With Selections") {
    @Previewable @State var purchases: [HotelChain: Int] = [.sackson: 2, .american: 1]
    StockPurchaseSheet(
        engine: .previewBuyingStocks(),
        purchases: $purchases,
        onConfirm: {},
        onSkip: {}
    )
}

#Preview("All 7 Chains Active") {
    @Previewable @State var purchases: [HotelChain: Int] = [:]
    StockPurchaseSheet(
        engine: .previewAllChainsActive(),
        purchases: $purchases,
        onConfirm: {},
        onSkip: {}
    )
}
