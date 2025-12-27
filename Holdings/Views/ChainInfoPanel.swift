//
//  ChainInfoPanel.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct ChainInfoPanel: View {
    let engine: GameEngine
    
    private var safeChains: [HotelChain] {
        HotelChain.allCases.filter { engine.board.isSafe($0) }
    }
    
    private var activeChains: [HotelChain] {
        HotelChain.allCases.filter {
            engine.board.activeChains().contains($0) && !engine.board.isSafe($0)
        }
    }
    
    private var inactiveChains: [HotelChain] {
        HotelChain.allCases.filter { !engine.board.activeChains().contains($0) }
    }

    var body: some View {
        List {
            if !safeChains.isEmpty {
                Section("Safe") {
                    ForEach(safeChains) { chain in
                        SafeChainRow(chain: chain, engine: engine)
                    }
                }
            }
            
            if !activeChains.isEmpty {
                Section("Active") {
                    ForEach(activeChains) { chain in
                        ActiveChainRow(chain: chain, engine: engine)
                    }
                }
            }
            
            if !inactiveChains.isEmpty {
                Section("Available") {
                    ForEach(inactiveChains) { chain in
                        InactiveChainRow(chain: chain)
                    }
                }
            }
        }
    }
}

struct SafeChainRow: View {
    let chain: HotelChain
    let engine: GameEngine
    
    private var size: Int { engine.board.chainSize(chain) }
    private var playerStock: Int { engine.currentPlayer.stockCount(for: chain) }

    var body: some View {
        LabeledContent {
            VStack(alignment: .trailing) {
                Text(currency: engine.stockPrice(for: chain))
                    .bold()
                Text("You: \(playerStock) · Bank: \(engine.availableStock(for: chain))")
            }
        } label: {
            Label {
                Text(chain.displayName)
                Text("\(size) tiles")
            } icon: {
                ChainShape(chain: chain)
            }
        }
    }
}

struct ActiveChainRow: View {
    let chain: HotelChain
    let engine: GameEngine
    
    private var size: Int { engine.board.chainSize(chain) }
    private var playerStock: Int { engine.currentPlayer.stockCount(for: chain) }

    var body: some View {
        LabeledContent {
            VStack(alignment: .trailing) {
                Text(currency: engine.stockPrice(for: chain))
                Text("You: \(playerStock) · Bank: \(engine.availableStock(for: chain))")
            }
        } label: {
            Label {
                Text(chain.displayName)
                Text("\(size) tiles · \(11 - size) to safe")
            } icon: {
                ChainShape(chain: chain)
            }
        }
    }
}

struct InactiveChainRow: View {
    let chain: HotelChain

    var body: some View {
        Label {
            Text(chain.displayName)
            Text("Tier \(chain.tier)")
        } icon: {
            ChainShape(chain: chain)
                .opacity(0.5)
        }
        .foregroundStyle(.secondary)
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
