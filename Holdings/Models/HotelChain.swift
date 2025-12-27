//
//  HotelChain.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

enum HotelChain: String, CaseIterable, Codable, Sendable, Identifiable {
    case sackson
    case worldwide
    case festival
    case imperial
    case american
    case continental
    case tower

    var id: String { rawValue }

    var displayName: String {
        rawValue.capitalized
    }

    var tier: Int {
        switch self {
        case .sackson, .worldwide: 1
        case .festival, .imperial, .american: 2
        case .continental, .tower: 3
        }
    }

    var color: Color {
        switch self {
        case .sackson: .red
        case .worldwide: .brown
        case .festival: .green
        case .imperial: .yellow
        case .american: .blue
        case .continental: .purple
        case .tower: .orange
        }
    }
}
