//
//  PriceChart.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation

enum PriceChart {
    /// Stock price based on chain tier and size
    static func stockPrice(chain: HotelChain, size: Int) -> Int {
        let basePrice = basePriceForSize(size)
        let tierBonus = (chain.tier - 1) * 100
        return basePrice + tierBonus
    }

    /// Majority (primary) shareholder bonus
    static func majorityBonus(chain: HotelChain, size: Int) -> Int {
        stockPrice(chain: chain, size: size) * 10
    }

    /// Minority (secondary) shareholder bonus
    static func minorityBonus(chain: HotelChain, size: Int) -> Int {
        stockPrice(chain: chain, size: size) * 5
    }

    private static func basePriceForSize(_ size: Int) -> Int {
        switch size {
        case ...1: 0    // Chain needs at least 2 tiles to be active
        case 2: 200
        case 3: 300
        case 4: 400
        case 5: 500
        case 6...10: 600
        case 11...20: 700
        case 21...30: 800
        case 31...40: 900
        default: 1000  // 41+
        }
    }
}
