# Holdings

A hotel empire strategy game for iOS, inspired by the classic board game Acquire.

## About the Game

Holdings is an investment and expansion strategy game where players compete to build the most valuable hotel empire. Place tiles on the board to establish hotel chains, buy stocks, and profit from mergers. The player with the most money at the end wins.

### How to Play

1. **Place Tiles**: On your turn, place one of your tiles on the board
2. **Found Chains**: When tiles connect, you can establish a new hotel chain and receive a founder's stock bonus
3. **Buy Stocks**: Purchase up to 3 stocks per turn from any active hotel chains
4. **Mergers**: When chains connect, the larger chain acquires the smaller one. Shareholders receive bonuses and can sell, trade, or keep their stocks
5. **Safe Chains**: Chains with 11+ tiles cannot be acquired
6. **Game End**: The game ends when all chains are safe, or any chain reaches 41 tiles. All stocks are liquidated and the richest player wins

### Hotel Chains

| Chain | Tier | Color | Shape |
|-------|------|-------|-------|
| Sackson | 1 | Red | ● |
| Worldwide | 1 | Brown | ▲ |
| Festival | 2 | Green | ■ |
| Imperial | 2 | Yellow | ◆ |
| American | 2 | Blue | ⬠ |
| Continental | 3 | Purple | ⬡ |
| Tower | 3 | Orange | ⯃ |

Higher tier chains have more valuable stocks.

## Requirements

- iOS 18.0+
- Xcode 16.0+
- Swift 6

## Architecture

Holdings uses modern SwiftUI patterns without ViewModels or MVVM:

- **Views as State Expressions**: Views are pure expressions of state using SwiftUI primitives
- **@Observable**: Shared game state managed through the `GameEngine` class
- **SwiftData**: Game persistence for save/resume functionality
- **Swift Concurrency**: Async/await for AI decision-making delays
- **Grid Layout**: Board rendered using SwiftUI `Grid` for responsive sizing

### Project Structure

```
Holdings/
├── HoldingsApp.swift          # App entry point
├── Design+Const.swift         # Design constants and helpers
├── PreviewHelpers.swift       # SwiftUI preview factories
├── Models/
│   ├── Board.swift            # Game board state
│   ├── GameState.swift        # Complete game state
│   ├── HotelChain.swift       # Hotel chain definitions
│   ├── Player.swift           # Player model
│   ├── Position.swift         # Board position
│   ├── SavedGame.swift        # SwiftData persistence
│   └── Tile.swift             # Tile model
├── Engine/
│   ├── GameEngine.swift       # Core game logic
│   └── PriceChart.swift       # Stock pricing calculations
├── AI/
│   └── AIPlayer.swift         # Computer opponent logic
└── Views/
    ├── ContentView.swift      # Root view with save/resume
    ├── MainMenuView.swift     # Game setup sheet
    ├── GameView.swift         # Main game interface
    ├── BoardView.swift        # Interactive game board
    ├── ChainInfoPanel.swift   # Hotel chain inspector
    ├── PlayerInfoBar.swift    # Player status display
    ├── StockPurchaseSheet.swift
    ├── FoundChainSheet.swift
    ├── MergerDecisionSheet.swift
    └── GameLogView.swift
```

## Features

- Single-player vs AI opponents (2-6 players)
- Automatic game saving with SwiftData
- Resume interrupted games
- Visual chain identification with unique colors and shapes
- Chain status inspector showing safe, active, and available chains
- Step-by-step AI turns for better game flow visibility

## Building

1. Open `Holdings.xcodeproj` in Xcode 16+
2. Select an iOS 18+ simulator or device
3. Build and run (⌘R)

## License

This project is for educational purposes. The original Acquire board game is © Hasbro/Avalon Hill.

