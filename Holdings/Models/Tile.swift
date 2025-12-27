//
//  Tile.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import Foundation

struct Tile: Identifiable, Hashable, Codable, Sendable {
    let position: Position

    var id: Position { position }

    var displayName: String { position.displayName }
}
