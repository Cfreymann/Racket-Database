# Debugger 🪳

A simple, cartoon-style iPhone game about squashing bugs fast.

This folder is a **self-contained Xcode project**. It shares nothing with the rest of the
repository it currently lives in, so you can move the whole `Debugger/` folder into its own repo
as-is (`git mv`, or copy it and run `git init`).

## Running it

1. Open `Debugger.xcodeproj` in **Xcode 16 or newer**. The project uses folder-synchronized groups,
   so any Swift file added under `Debugger/` is picked up automatically.
2. Pick an iPhone simulator, or your phone. For a real device, choose your team under
   *Signing & Capabilities* and change the bundle ID (`com.example.debugger`).
3. Run with ⌘R.

The app targets iOS 17+, portrait iPhone. It uses only SwiftUI and UIKit, with no third-party code
and no image assets except the app icon. Every bug, swatter, spray can and floor tile is drawn in
code.

## How to play

* **Tap** to swat. Every bug under the swatter takes damage.
* **Drag** to spray. A poison mist follows your finger and hurts bugs standing in it. The can
  drains while you spray and refills when you stop.
* Squash the level's quota before the timer runs out. Kills close together build a **combo**,
  which pays bonus coins.
* After each run you keep your bug bounties. Clearing the level adds a completion bonus plus a speed
  bonus for the seconds left. More time left also earns more stars.
* Spend coins in **Upgrades** on the Fly Swatter (bigger and stronger, 5 tiers) and the Bug Spray
  (bigger tank, more potent, bigger cloud, faster refill, 5 tiers).

### Level 1: Kitchen Panic

Squash 30 bugs in 40 seconds.

| Bug        | HP | Speed     | Bounty | Appears after |
|------------|----|-----------|--------|---------------|
| Roach      | 1  | medium    | 5      | 0s            |
| Big Momma  | 3  | slow      | 15     | 8s            |
| Zoomer     | 1  | very fast | 10     | 16s           |

Bugs scurry around for a few seconds and then run for the edge. Any bug that escapes is a lost
bounty.

## Code layout

```
Debugger/
├── Debugger.xcodeproj
└── Debugger/
    ├── DebuggerApp.swift          App entry point
    ├── App/AppModel.swift         Screen routing + saved progress (coins, upgrades, stars)
    ├── Game/
    │   ├── LevelConfig.swift      Level definitions (add new levels to LevelConfig.all)
    │   ├── Upgrades.swift         Swatter and spray tiers and their costs
    │   ├── Entities.swift         Bug types, bugs, splats, effects
    │   ├── GameEngine.swift       Game loop: spawning, movement, swat/spray, scoring
    │   └── DisplayLink.swift      CADisplayLink wrapper that drives the engine
    ├── Rendering/
    │   ├── BugRenderer.swift      The cartoon cockroach, drawn with paths
    │   ├── ToolRenderer.swift     Swatter, spray can, mist
    │   └── SceneRenderer.swift    Draws a frame + the kitchen-tile floor
    ├── UI/                        Menu, game HUD and overlays, results, upgrade shop, theme
    └── Assets.xcassets            App icon + accent color
```

### Adding a level

Add a `LevelConfig` (duration, quota, spawn pacing, which bug types appear and when) to
`LevelConfig.all`. Then let `AppModel.currentLevel` pick the next level and turn on the
"Next Level" button in `ResultsView`.

### Art style

Bugs follow the reference cartoon roach: thick dark-brown outlines (`Palette.outline`), brick-red
legs, antennae and pronotum (`Palette.roachRed`), and a deep-brown oval body with a darker wing seam.
All colors live in `UI/Theme.swift`.
