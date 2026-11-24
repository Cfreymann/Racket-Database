import SwiftUI

/// Top-level app state: which screen is showing plus the player's saved progress
/// (coins, upgrade tiers, best star ratings). Progress persists in UserDefaults.
@MainActor
final class AppModel: ObservableObject {
    enum Screen: Equatable {
        case menu
        case game(runID: UUID)
        case results(LevelResult)
    }

    @Published var screen: Screen = .menu
    @Published var showShop = false

    @Published private(set) var coins: Int
    @Published private(set) var swatterTier: Int
    @Published private(set) var sprayTier: Int
    @Published private(set) var bestStars: [Int: Int]

    private enum Key {
        static let coins = "debugger.coins"
        static let swatter = "debugger.swatterTier"
        static let spray = "debugger.sprayTier"
        static let stars = "debugger.bestStars"
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
    }

    // MARK: - Current loadout

    /// Only one level exists in this demo; more get appended to `LevelConfig.all`.
    var currentLevel: LevelConfig { LevelConfig.all[0] }
    var swatter: SwatterStats { SwatterStats.tiers[swatterTier] }
    var spray: SprayStats { SprayStats.tiers[sprayTier] }

    // MARK: - Navigation

    func playCurrentLevel() {
        showShop = false
        screen = .game(runID: UUID())
    }

    func goToMenu() {
        screen = .menu
    }

    func complete(_ result: LevelResult) {
        coins += result.totalCoins
        if result.stars > (bestStars[result.levelNumber] ?? 0) {
            bestStars[result.levelNumber] = result.stars
        }
        save()
        screen = .results(result)
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

    /// Cost of the next tier, or nil when the item is maxed out.
    func nextCost(of kind: UpgradeKind) -> Int? {
        let costs = kind == .swatter ? SwatterStats.upgradeCosts : SprayStats.upgradeCosts
        let current = tier(of: kind)
        return current < costs.count ? costs[current] : nil
    }

    func canBuy(_ kind: UpgradeKind) -> Bool {
        guard let cost = nextCost(of: kind) else { return false }
        return coins >= cost
    }

    func buy(_ kind: UpgradeKind) {
        guard let cost = nextCost(of: kind), coins >= cost else { return }
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
        save()
    }

    private func save() {
        let defaults = UserDefaults.standard
        defaults.set(coins, forKey: Key.coins)
        defaults.set(swatterTier, forKey: Key.swatter)
        defaults.set(sprayTier, forKey: Key.spray)
        var raw: [String: Int] = [:]
        for (level, stars) in bestStars { raw[String(level)] = stars }
        defaults.set(raw, forKey: Key.stars)
    }
}
