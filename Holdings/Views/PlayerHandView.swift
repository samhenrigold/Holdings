//
//  PlayerHandView.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct PlayerHandView: View {
    let tiles: [Tile]
    let canPlay: Bool
    let engine: GameEngine
    let onTilePlayed: (Tile) -> Void

    var body: some View {
        VStack {
            Text("Your Tiles")
                .font(.headline)

            HStack {
                ForEach(tiles) { tile in
                    let isPlayable = canPlay && engine.canPlayTile(tile)
                    Button {
                        if isPlayable {
                            onTilePlayed(tile)
                        }
                    } label: {
                        TileView(
                            tile: tile,
                            isPlayable: isPlayable,
                            isUnplayable: !engine.canPlayTile(tile)
                        )
                    }
                    .buttonStyle(.plain)
                    .disabled(!isPlayable)
                }
            }
        }
        .padding()
    }
}

struct TileView: View {
    let tile: Tile
    let isPlayable: Bool
    let isUnplayable: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(backgroundColor)
                .frame(width: 50, height: 50)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .strokeBorder(isPlayable ? .green : .gray, lineWidth: isPlayable ? 2 : 1)
                )

            VStack(spacing: 2) {
                Text(tile.displayName)
                    .font(.caption)
                    .bold()

                if isUnplayable {
                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.red)
                }
            }
        }
        .opacity(isUnplayable ? 0.5 : 1)
    }

    private var backgroundColor: Color {
        if isPlayable {
            return .green.opacity(0.2)
        }
        return .secondary.opacity(0.1)
    }
}

#Preview("Can Play Tiles") {
    @Previewable @State var engine = GameEngine(playerCount: 4, humanPlayerIndex: 0)
    PlayerHandView(
        tiles: engine.currentPlayer.tiles,
        canPlay: true,
        engine: engine,
        onTilePlayed: { _ in }
    )
}

#Preview("Not Your Turn") {
    @Previewable @State var engine = GameEngine(playerCount: 4, humanPlayerIndex: 0)
    PlayerHandView(
        tiles: engine.currentPlayer.tiles,
        canPlay: false,
        engine: engine,
        onTilePlayed: { _ in }
    )
}

#Preview("Mid-Game Tiles") {
    @Previewable @State var engine = GameEngine.previewWithActiveChains()
    PlayerHandView(
        tiles: engine.currentPlayer.tiles,
        canPlay: true,
        engine: engine,
        onTilePlayed: { _ in }
    )
}
