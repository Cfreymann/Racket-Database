import Foundation

struct SpawnRule {
    let kind: BugKind
    /// Seconds into the level before this bug type can appear.
    let after: Double
    let weight: Double
}

enum FloorStyle {
    case kitchen, picnic
}

/// Everything that defines a level. Add new levels to `LevelConfig.all`.
struct LevelConfig {
    let number: Int
    let title: String
    let floor: FloorStyle
    /// Bug shown on the level's menu card and HUD.
    let icon: BugKind
    /// Whether the bug spray can be used in this level.
    let sprayEnabled: Bool
    /// A bug type that appears for the first time in this level (shown on the intro card).
    let newBug: BugKind?
    let duration: Double
    let quota: Int
    let spawnIntervalStart: Double
    let spawnIntervalEnd: Double
    let maxAlive: Int
    let spawnRules: [SpawnRule]
    let completionBonus: Int
    let timeBonusPerSecond: Int
    let threeStarTimeLeft: Double
    let twoStarTimeLeft: Double

    var objective: String {
        "Squash \(quota) bugs in \(Int(duration)) seconds, or the level restarts!"
    }

    func stars(timeLeft: Double) -> Int {
        if timeLeft >= threeStarTimeLeft { return 3 }
        if timeLeft >= twoStarTimeLeft { return 2 }
        return 1
    }

    /// The bug spray unlocks (in play and in the shop) once the player reaches this level.
    static let sprayUnlockLevel = 2

    static let kitchen = LevelConfig(
        number: 1,
        title: "Kitchen Panic",
        floor: .kitchen,
        icon: .roach,
        sprayEnabled: false,
        newBug: nil,
        duration: 40,
        quota: 25,
        spawnIntervalStart: 1.0,
        spawnIntervalEnd: 0.45,
        maxAlive: 14,
        spawnRules: [
            SpawnRule(kind: .roach, after: 0, weight: 6),
            SpawnRule(kind: .bigRoach, after: 8, weight: 1.5),
            SpawnRule(kind: .zoomer, after: 16, weight: 2),
        ],
        completionBonus: 100,
        timeBonusPerSecond: 5,
        threeStarTimeLeft: 14,
        twoStarTimeLeft: 6
    )

    static let backyard = LevelConfig(
        number: 2,
        title: "Backyard BBQ",
        floor: .picnic,
        icon: .fly,
        sprayEnabled: true,
        newBug: .fly,
        duration: 45,
        quota: 35,
        spawnIntervalStart: 0.85,
        spawnIntervalEnd: 0.4,
        maxAlive: 16,
        spawnRules: [
            SpawnRule(kind: .fly, after: 0, weight: 5),
            SpawnRule(kind: .roach, after: 0, weight: 3),
            SpawnRule(kind: .bigRoach, after: 10, weight: 1.2),
            SpawnRule(kind: .zoomer, after: 18, weight: 1.5),
        ],
        completionBonus: 150,
        timeBonusPerSecond: 6,
        threeStarTimeLeft: 14,
        twoStarTimeLeft: 6
    )

    static let all: [LevelConfig] = [kitchen, backyard]
}

/// Summary handed from a finished game to the results or fail screen.
struct LevelResult: Equatable {
    let levelIndex: Int
    let levelNumber: Int
    let levelTitle: String
    let won: Bool
    let kills: Int
    let quota: Int
    let escaped: Int
    let bestCombo: Int
    let timeLeft: Double
    let bounty: Int
    let completionBonus: Int
    let timeBonus: Int
    let stars: Int
    /// Set by AppModel when this win unlocked a new level.
    var unlockedLevelNumber: Int? = nil

    var totalCoins: Int { bounty + completionBonus + timeBonus }
}
