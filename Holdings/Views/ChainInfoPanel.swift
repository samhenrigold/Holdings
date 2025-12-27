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
        ScrollView {
            VStack(alignment: .leading) {
                Text("Hotel Chains")
                    .font(.headline)

                ForEach(HotelChain.allCases) { chain in
                    ChainInfoRow(chain: chain, engine: engine)
                }
            }
        }
        .contentMargins(16, for: .scrollContent)
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
        HStack {
            Circle()
                .fill(chain.color)
                .frame(width: 12, height: 12)

            VStack(alignment: .leading) {
                HStack {
                    Text(chain.displayName)
                        .font(.subheadline)

                    if isSafe {
                        Image(systemName: "lock.fill")
                            .font(.caption2)
                            .foregroundStyle(.green)
                    }
                }

                if isActive {
                    Text("Size: \(size) • $\(engine.stockPrice(for: chain))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if isActive {
                VStack(alignment: .trailing) {
                    Text("You: \(playerStock)")
                        .font(.caption)
                    Text("Avail: \(engine.availableStock(for: chain))")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            } else {
                Text("Inactive")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
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
