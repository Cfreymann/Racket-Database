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

* **Tap** to swat. Every bug under the swatter takes damage. Then the swatter needs a moment to
  **recharge**. The badge in the bottom-left corner shows when it's ready, and taps before then
  do nothing.
* **Drag** to spray (unlocks in Level 2). A poison mist follows your finger and hurts bugs standing
  in it. The can drains while you spray and refills when you stop.
* Squash the level's quota before the timer runs out. **If time runs out, the level restarts**
  after a 5-second countdown. You can restart right away, upgrade first, or quit to the menu.
* You always keep your bug bounties. Clearing a level adds a completion bonus plus a speed bonus for
  the seconds left, earns up to 3 stars, and unlocks the next level. Kills close together build a
  **combo** for extra coins.
* Spend coins in **Upgrades**:
  * **Fly Swatter** (5 tiers): bigger, stronger, and faster recharge (0.55s down to 0.20s).
  * **Bug Spray** (5 tiers, locked until Level 2): bigger tank, more potent, bigger cloud, faster refill.

### Levels

| Level | Name          | Goal                    | Spray | New                                   |
|-------|---------------|-------------------------|-------|---------------------------------------|
| 1     | Kitchen Panic | 25 bugs in 40 seconds   | no    | roaches                               |
| 2     | Backyard BBQ  | 35 bugs in 45 seconds   | yes   | house flies, picnic-blanket floor     |

| Bug        | HP | Movement                                  | Bounty |
|------------|----|-------------------------------------------|--------|
| Roach      | 1  | scurries, freezes, darts                  | 5      |
| Big Momma  | 3  | slow                                      | 15     |
| Zoomer     | 1  | very fast                                 | 10     |
| House Fly  | 1  | darts in straight bursts, then hovers     | 8      |

Bugs hang around for a few seconds and then run for the edge. Any bug that escapes is a lost
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
    ├── UI/                        Menu, game HUD and overlays, fail/restart, results, shop, theme
    └── Assets.xcassets            App icon + accent color
```

### Adding a level

Add a `LevelConfig` to `LevelConfig.all`, with its duration, quota, spawn pacing, which bug types
appear and when, floor style, and whether spray is allowed. The menu, unlocking and the
"Next Level" button pick it up automatically.

## Web version

`web/index.html` is a single-file browser port of the same game (same levels, art and upgrades),
for playing on a phone without Xcode. It saves progress in the browser's local storage.

### Art style

Bugs follow the reference cartoon roach: thick dark-brown outlines (`Palette.outline`), brick-red
legs, antennae and pronotum (`Palette.roachRed`), and a deep-brown oval body with a darker wing seam.
All colors live in `UI/Theme.swift`.
