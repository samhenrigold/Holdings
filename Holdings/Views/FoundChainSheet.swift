//
//  FoundChainSheet.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct FoundChainSheet: View {
    let options: [HotelChain]
    let onSelect: (HotelChain) -> Void

    private var tier1Chains: [HotelChain] {
        options.filter { $0.tier == 1 }
    }

    private var tier2Chains: [HotelChain] {
        options.filter { $0.tier == 2 }
    }

    private var tier3Chains: [HotelChain] {
        options.filter { $0.tier == 3 }
    }

    var body: some View {
        NavigationStack {
            List {
                tierSection("Tier 1", chains: tier1Chains)
                tierSection("Tier 2", chains: tier2Chains)
                tierSection("Tier 3", chains: tier3Chains)
            }
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle("Found a Hotel Chain")
        }
    }

    @ViewBuilder
    private func tierSection(_ title: String, chains: [HotelChain]) -> some View {
        if !chains.isEmpty {
            Section(title) {
                ForEach(chains) { chain in
                    Button {
                        onSelect(chain)
                    } label: {
                        Label {
                            Text(chain.displayName)
                        } icon: {
                            ChainShape(chain: chain)
                        }
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview("All Chains Available") {
    FoundChainSheet(options: HotelChain.allCases, onSelect: { _ in })
}

#Preview("Limited Options") {
    FoundChainSheet(options: [.sackson, .worldwide, .festival], onSelect: { _ in })
}

#Preview("Only High Tier Left") {
    FoundChainSheet(options: [.continental, .tower], onSelect: { _ in })
}

#Preview("Single Option") {
    FoundChainSheet(options: [.imperial], onSelect: { _ in })
}
