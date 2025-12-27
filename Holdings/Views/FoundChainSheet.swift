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

    var body: some View {
        NavigationStack {
            List(options) { chain in
                Button {
                    onSelect(chain)
                } label: {
                    HStack {
                        Circle()
                            .fill(chain.color)
                            .frame(width: 24, height: 24)

                        Text(chain.displayName)

                        Spacer()

                        Text("Tier \(chain.tier)")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("Found a Hotel Chain")
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
