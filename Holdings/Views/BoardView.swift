//
//  BoardView.swift
//  Holdings
//
//  Created by Sam on 2025-12-27.
//

import SwiftUI

struct BoardView: View {
    let engine: GameEngine
    let onTilePlaced: (Tile) -> Void

    @State private var selectedTile: Tile?
    
    // Check if all 7 hotel chains are active (blocking new chain founding)
    private var allChainsActive: Bool {
        engine.board.activeChains().count >= 7
    }

    var body: some View {
        GeometryReader { geometry in
            let cellSize = min(
                geometry.size.width / 12,
                geometry.size.height / 9
            )

            VStack(spacing: 1) {
                ForEach(0..<9, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(1...12, id: \.self) { column in
                            let position = Position(column: column, row: row)
                            let tileStatus = getTileStatus(at: position)
                            BoardCellView(
                                position: position,
                                board: engine.board,
                                isSelected: selectedTile?.position == position,
                                tileStatus: tileStatus,
                                onTap: { handleCellTap(position) }
                            )
                            .frame(width: cellSize, height: cellSize)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .padding()
    }
    
    enum TileStatus {
        case empty
        case canPlay
        case blockedNoHotels  // Would found chain but all 7 are active
        case blockedSafeChains  // Would merge two safe chains
        case notYourTile
    }
    
    private func getTileStatus(at position: Position) -> TileStatus {
        guard engine.turnPhase == .placeTile,
              engine.currentPlayer.isHuman else { return .empty }
        
        guard let tile = engine.currentPlayer.tiles.first(where: { $0.position == position }) else {
            return .empty
        }
        
        // Check why it might be blocked
        let result = engine.analyzeTilePlacement(tile)
        switch result {
        case .illegal(let reason):
            if reason.contains("seven hotel chains") {
                return .blockedNoHotels
            } else if reason.contains("safe") {
                return .blockedSafeChains
            }
            return .notYourTile
        default:
            return .canPlay
        }
    }

    private func handleCellTap(_ position: Position) {
        guard let tile = engine.currentPlayer.tiles.first(where: { $0.position == position }),
              engine.canPlayTile(tile) else { return }

        onTilePlaced(tile)
    }
}

struct BoardCellView: View {
    let position: Position
    let board: Board
    let isSelected: Bool
    let tileStatus: BoardView.TileStatus
    let onTap: () -> Void
    
    private var canPlace: Bool {
        tileStatus == .canPlay
    }

    var body: some View {
        Button {
            if canPlace {
                onTap()
            }
        } label: {
            ZStack {
                Rectangle()
                    .fill(AnyShapeStyle(backgroundColor))
                    .overlay(
                        Rectangle()
                            .strokeBorder(AnyShapeStyle(borderColor), lineWidth: isSelected || canPlace ? 2 : 0.5)
                    )

                if board.hasTile(at: position) {
                    if let chain = board.chain(at: position) {
                        Image(systemName: "building.2.fill")
                            .foregroundStyle(chain.color)
                            .font(.title3)
                    } else {
                        Circle()
                            .fill(.gray)
                            .padding(8)
                    }
                } else {
                    VStack(spacing: 0) {
                        Text(position.displayName)
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundStyle(canPlace ? .primary : .tertiary)
                            .bold(canPlace)
                        
                        // Show why tile is blocked
                        if tileStatus == .blockedNoHotels {
                            Image(systemName: "building.2.crop.circle.badge.exclamationmark")
                                .font(.system(size: 8))
                                .foregroundStyle(.orange)
                        } else if tileStatus == .blockedSafeChains {
                            Image(systemName: "lock.fill")
                                .font(.system(size: 8))
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
        }
        .buttonStyle(.plain)
        .disabled(!canPlace)
    }

    private var backgroundColor: any ShapeStyle {
        switch tileStatus {
        case .canPlay:
            return .green.tertiary
        case .blockedNoHotels:
            return .orange.opacity(0.15)
        case .blockedSafeChains:
            return .red.opacity(0.15)
        default:
            if board.hasTile(at: position) {
                if let chain = board.chain(at: position) {
                    return chain.color.tertiary
                }
                return .secondary
            }
            return .clear
        }
    }

    private var borderColor: any ShapeStyle {
        if isSelected {
            return .blue
        }
        switch tileStatus {
        case .canPlay:
            return .green
        case .blockedNoHotels:
            return .orange
        case .blockedSafeChains:
            return .red
        default:
            return .secondary
        }
    }
}

#Preview("Empty Board") {
    BoardView(engine: GameEngine(playerCount: 4, humanPlayerIndex: 0), onTilePlaced: { _ in })
}

#Preview("Active Chains") {
    BoardView(engine: .previewWithActiveChains(), onTilePlaced: { _ in })
}

#Preview("Safe Chain") {
    BoardView(engine: .previewWithSafeChain(), onTilePlaced: { _ in })
}

#Preview("All 7 Chains Active") {
    BoardView(engine: .previewAllChainsActive(), onTilePlaced: { _ in })
}
