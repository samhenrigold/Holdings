//
//  ChainInfoPanel.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct ChainInfoPanel: View {
    let engine: GameEngine

    var body: some View {
        List {
            Section("Hotel Chains") {
                ForEach(HotelChain.allCases) { chain in
                    ChainInfoRow(chain: chain, engine: engine)
                }
            }
        }
        .listStyle(.plain)
    }
}

struct ChainInfoRow: View {
    let chain: HotelChain
    let engine: GameEngine

    private var isActive: Bool {
        engine.board.activeChains().contains(chain)
    }

    private var size: Int {
        engine.board.chainSize(chain)
    }

    private var isSafe: Bool {
        engine.board.isSafe(chain)
    }

    private var playerStock: Int {
        engine.currentPlayer.stockCount(for: chain)
    }

    var body: some View {
        LabeledContent {
            if isActive {
                VStack(alignment: .trailing) {
                    Text("You: \(playerStock)")
                    Text("Bank: \(engine.availableStock(for: chain))")
                        .foregroundStyle(.secondary)
                }
                .font(.caption)
            } else {
                Text("Inactive")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        } label: {
            Label {
                VStack(alignment: .leading) {
                    HStack {
                        Text(chain.displayName)
                        if isSafe {
                            Image(systemName: "lock.fill")
                                .font(.caption2)
                                .foregroundStyle(.green)
                        }
                    }
                    
                    if isActive {
                        Text("Size: \(size) · \(Text(currency: engine.stockPrice(for: chain)))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } icon: {
                Circle()
                    .fill(chain.color)
                    .frame(width: 12, height: 12)
            }
        }
        .opacity(isActive ? 1 : 0.5)
    }
}

#Preview("No Active Chains") {
    ChainInfoPanel(engine: GameEngine(playerCount: 4, humanPlayerIndex: 0))
}

#Preview("Multiple Chains Active") {
    ChainInfoPanel(engine: .previewWithActiveChains())
}

#Preview("Safe Chain Present") {
    ChainInfoPanel(engine: .previewWithSafeChain())
}

#Preview("All Chains Active") {
    ChainInfoPanel(engine: .previewAllChainsActive())
}
