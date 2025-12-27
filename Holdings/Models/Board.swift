//
//  Board.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation

struct Board: Codable, Sendable {
    /// Positions that have tiles placed on them
    private(set) var placedTiles: Set<Position> = []

    /// Which chain (if any) each position belongs to
    private(set) var chainMembership: [Position: HotelChain] = [:]

    /// Positions belonging to each active chain
    var chainPositions: [HotelChain: Set<Position>] {
        var result: [HotelChain: Set<Position>] = [:]
        for (position, chain) in chainMembership {
            result[chain, default: []].insert(position)
        }
        return result
    }

    func chainSize(_ chain: HotelChain) -> Int {
        chainMembership.values.filter { $0 == chain }.count
    }

    func isSafe(_ chain: HotelChain) -> Bool {
        chainSize(chain) >= GameRules.safeChainSize
    }

    func activeChains() -> Set<HotelChain> {
        Set(chainMembership.values)
    }

    func chain(at position: Position) -> HotelChain? {
        chainMembership[position]
    }

    func hasTile(at position: Position) -> Bool {
        placedTiles.contains(position)
    }

    /// Returns positions that are placed but not part of any chain (independent tiles)
    func independentTiles() -> Set<Position> {
        placedTiles.subtracting(Set(chainMembership.keys))
    }

    // MARK: - Mutations

    mutating func placeTile(at position: Position) {
        placedTiles.insert(position)
    }

    mutating func assignChain(_ chain: HotelChain, to positions: Set<Position>) {
        for position in positions {
            chainMembership[position] = chain
        }
    }

    mutating func removeChain(_ chain: HotelChain) {
        chainMembership = chainMembership.filter { $0.value != chain }
    }

    /// Finds all positions connected to a given position (flood fill)
    func connectedPositions(from start: Position) -> Set<Position> {
        guard placedTiles.contains(start) else { return [] }

        var visited: Set<Position> = []
        var queue: [Position] = [start]

        while let current = queue.popLast() {
            guard !visited.contains(current) else { continue }
            visited.insert(current)

            for adjacent in current.adjacentPositions where placedTiles.contains(adjacent) {
                if !visited.contains(adjacent) {
                    queue.append(adjacent)
                }
            }
        }

        return visited
    }
}
