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
        Label {
            VStack(alignment: .leading) {
                Text(player.name)
                    .font(.headline)
                Text(currency: player.money)
            }
        } icon: {
            if player.isHuman {
                Image(systemName: "person.fill")
            } else {
                Image(systemName: "cpu")
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .fill(isCurrent ? AnyShapeStyle(Color.primary) : AnyShapeStyle(.fill.tertiary))
                .phaseAnimator([false, isCurrent]) { content, value in
                    content
                        .opacity(value ? 0.6 : 1)
                } animation: { _ in
                        .easeInOut(duration: 1.5)
                }
        }
        .foregroundStyle(isCurrent ? AnyShapeStyle(.background) : AnyShapeStyle(Color.primary))
        .animation(.default, value: isCurrent)
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
