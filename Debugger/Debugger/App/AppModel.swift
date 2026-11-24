import SwiftUI

/// Top-level app state: which screen is showing plus the player's saved progress
/// (coins, upgrade tiers, unlocked levels, best star ratings). Progress persists in UserDefaults.
@MainActor
final class AppModel: ObservableObject {
    enum Screen: Equatable {
        case menu
        case game(levelIndex: Int, runID: UUID)
        case results(LevelResult)
        /// Time ran out; the level restarts automatically after a countdown.
        case failed(LevelResult)
    }

    /// Seconds the fail screen waits before restarting the level.
    static let restartSeconds: Double = 5

    @Published var screen: Screen = .menu
    @Published var showShop = false
    /// Set when the player chose "Upgrade first" on the fail screen: closing the shop restarts the level.
    @Published var restartAfterShop = false

    @Published private(set) var coins: Int
    @Published private(set) var swatterTier: Int
    @Published private(set) var sprayTier: Int
    @Published private(set) var bestStars: [Int: Int]
    /// Highest level number the player may play.
    @Published private(set) var unlockedLevel: Int
    @Published private(set) var lastLevelIndex = 0

    private enum Key {
        static let coins = "debugger.coins"
        static let swatter = "debugger.swatterTier"
        static let spray = "debugger.sprayTier"
        static let stars = "debugger.bestStars"
        static let unlocked = "debugger.unlockedLevel"
    }

    init() {
        let defaults = UserDefaults.standard
        coins = max(0, defaults.integer(forKey: Key.coins))
        swatterTier = min(max(0, defaults.integer(forKey: Key.swatter)), SwatterStats.tiers.count - 1)
        sprayTier = min(max(0, defaults.integer(forKey: Key.spray)), SprayStats.tiers.count - 1)
        let raw = defaults.dictionary(forKey: Key.stars) as? [String: Int] ?? [:]
        var stars: [Int: Int] = [:]
        for (key, value) in raw {
            if let level = Int(key) { stars[level] = value }
        }
        bestStars = stars
        // Older saves had no unlock record: anyone who earned stars on level 1 has cleared it.
        var unlocked = max(1, defaults.integer(forKey: Key.unlocked))
        if (stars[1] ?? 0) > 0 { unlocked = max(unlocked, 2) }
        unlockedLevel = min(unlocked, LevelConfig.all.count)
    }

    // MARK: - Current loadout

    var swatter: SwatterStats { SwatterStats.tiers[swatterTier] }
    var spray: SprayStats { SprayStats.tiers[sprayTier] }
    var isSprayUnlocked: Bool { unlockedLevel >= LevelConfig.sprayUnlockLevel }

    func level(at index: Int) -> LevelConfig { LevelConfig.all[index] }

    func isUnlocked(_ level: LevelConfig) -> Bool { level.number <= unlockedLevel }

    // MARK: - Navigation

    func play(levelIndex: Int) {
        guard LevelConfig.all.indices.contains(levelIndex), isUnlocked(level(at: levelIndex)) else { return }
        showShop = false
        restartAfterShop = false
        lastLevelIndex = levelIndex
        screen = .game(levelIndex: levelIndex, runID: UUID())
    }

    func restartLevel() {
        play(levelIndex: lastLevelIndex)
    }

    func goToMenu() {
        restartAfterShop = false
        screen = .menu
    }

    /// "Upgrade first" on the fail screen.
    func openShopThenRestart() {
        restartAfterShop = true
        showShop = true
    }

    func shopDismissed() {
        if restartAfterShop, case .failed = screen {
            restartLevel()
        }
        restartAfterShop = false
    }

    func complete(_ result: LevelResult) {
        // Bug bounties are always kept, so a failed run still helps pay for upgrades.
        coins += result.totalCoins
        guard result.won else {
            save()
            screen = .failed(result)
            return
        }
        var finished = result
        if result.stars > (bestStars[result.levelNumber] ?? 0) {
            bestStars[result.levelNumber] = result.stars
        }
        let next = min(LevelConfig.all.count, result.levelNumber + 1)
        if next > unlockedLevel {
            unlockedLevel = next
            finished.unlockedLevelNumber = next
        }
        save()
        screen = .results(finished)
    }

    // MARK: - Upgrades

    func tier(of kind: UpgradeKind) -> Int {
        switch kind {
        case .swatter: swatterTier
        case .spray: sprayTier
        }
    }

    func maxTier(of kind: UpgradeKind) -> Int {
        switch kind {
        case .swatter: SwatterStats.tiers.count - 1
        case .spray: SprayStats.tiers.count - 1
        }
    }

    func isLocked(_ kind: UpgradeKind) -> Bool {
        kind == .spray && !isSprayUnlocked
    }

    /// Cost of the next tier, or nil when the item is maxed out.
    func nextCost(of kind: UpgradeKind) -> Int? {
        let costs = kind == .swatter ? SwatterStats.upgradeCosts : SprayStats.upgradeCosts
        let current = tier(of: kind)
        return current < costs.count ? costs[current] : nil
    }

    func canBuy(_ kind: UpgradeKind) -> Bool {
        guard !isLocked(kind), let cost = nextCost(of: kind) else { return false }
        return coins >= cost
    }

    func buy(_ kind: UpgradeKind) {
        guard canBuy(kind), let cost = nextCost(of: kind) else { return }
        coins -= cost
        switch kind {
        case .swatter: swatterTier += 1
        case .spray: sprayTier += 1
        }
        save()
    }

    func resetProgress() {
        coins = 0
        swatterTier = 0
        sprayTier = 0
        bestStars = [:]
        unlockedLevel = 1
        save()
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(coins, forKey: Key.coins)
        defaults.set(swatterTier, forKey: Key.swatter)
        defaults.set(sprayTier, forKey: Key.spray)
        defaults.set(unlockedLevel, forKey: Key.unlocked)
        var raw: [String: Int] = [:]
        for (level, stars) in bestStars { raw[String(level)] = stars }
        defaults.set(raw, forKey: Key.stars)
    }
}
