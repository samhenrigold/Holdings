//
//  Player.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation

struct Player: Identifiable, Codable, Sendable {
    let id: UUID
    var name: String
    var isHuman: Bool
    var money: Int
    var stocks: [HotelChain: Int]
    var tiles: [Tile]

    init(id: UUID = UUID(), name: String, isHuman: Bool) {
        self.id = id
        self.name = name
        self.isHuman = isHuman
        self.money = GameRules.startingMoney
        self.stocks = [:]
        self.tiles = []
    }

    func stockCount(for chain: HotelChain) -> Int {
        stocks[chain] ?? 0
    }

    mutating func addStock(_ chain: HotelChain, count: Int = 1) {
        stocks[chain, default: 0] += count
    }

    mutating func removeStock(_ chain: HotelChain, count: Int = 1) {
        let current = stocks[chain] ?? 0
        stocks[chain] = max(0, current - count)
    }
}
