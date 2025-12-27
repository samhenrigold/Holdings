//
//  PlayerInfoBar.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct PlayerInfoBar: View {
    let engine: GameEngine

    var body: some View {
        ScrollView(.horizontal) {
            HStack {
                ForEach(engine.state.players) { player in
                    PlayerBadge(
                        player: player,
                        isCurrent: player.id == engine.currentPlayer.id
                    )
                }
            }
        }
        .scrollIndicators(.hidden)
        .contentMargins(8, for: .scrollContent)
    }
}

struct PlayerBadge: View {
    let player: Player
    let isCurrent: Bool

    var body: some View {
        VStack {
            HStack {
                if player.isHuman {
                    Image(systemName: "person.fill")
                } else {
                    Image(systemName: "cpu")
                }
                Text(player.name)
                    .font(.headline)
            }

            Text("$\(player.money)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding()
        .background(isCurrent ? Color.blue.opacity(0.2) : Color.secondary.opacity(0.1))
        .clipShape(.rect(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .strokeBorder(isCurrent ? .blue : .clear, lineWidth: 2)
        )
    }
}

#Preview("4 Players - New Game") {
    PlayerInfoBar(engine: GameEngine(playerCount: 4, humanPlayerIndex: 0))
}

#Preview("4 Players - Mid Game") {
    PlayerInfoBar(engine: .previewWithActiveChains())
}

#Preview("3 Players") {
    PlayerInfoBar(engine: .previewWithSafeChain())
}

#Preview("6 Players") {
    PlayerInfoBar(engine: GameEngine(playerCount: 6, humanPlayerIndex: 0))
}
