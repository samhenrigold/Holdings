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
                    LabeledContent {
                        Text("Tier \(chain.tier)")
                    } label: {
                        Label {
                            Text(chain.displayName)
                        } icon: {
                            Image(systemName: "circle.fill")
                                .foregroundStyle(chain.color)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
