//
//  Position.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation

struct Position: Hashable, Codable, Sendable {
    let column: Int  // 1-9
    let row: Int     // 0-11 (A-L)

    static let columns = 1...9
    static let rows = 0...11

    var rowLetter: Character {
        Character(UnicodeScalar(65 + row)!)  // A=0, B=1, etc.
    }

    var displayName: String {
        "\(column)\(rowLetter)"
    }

    /// All valid board positions
    static var all: [Position] {
        rows.flatMap { row in
            columns.map { column in
                Position(column: column, row: row)
            }
        }
    }

    /// Returns orthogonally adjacent positions (not diagonal)
    var adjacentPositions: [Position] {
        [
            Position(column: column - 1, row: row),
            Position(column: column + 1, row: row),
            Position(column: column, row: row - 1),
            Position(column: column, row: row + 1)
        ].filter(\.isValid)
    }

    var isValid: Bool {
        Self.columns.contains(column) && Self.rows.contains(row)
    }

    /// Distance from 1A (for determining first player)
    var distanceFrom1A: Int {
        (column - 1) + row
    }
}

extension Position: Comparable {
    static func < (lhs: Position, rhs: Position) -> Bool {
        lhs.distanceFrom1A < rhs.distanceFrom1A
    }
}
