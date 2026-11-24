import Foundation

struct SpawnRule {
    let kind: BugKind
    /// Seconds into the level before this bug type can appear.
    let after: Double
    let weight: Double
}

/// Everything that defines a level. Add new levels to `LevelConfig.all`.
struct LevelConfig {
    let number: Int
    let title: String
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
        "Squash \(quota) bugs in \(Int(duration)) seconds!"
    }

    func stars(timeLeft: Double) -> Int {
        if timeLeft >= threeStarTimeLeft { return 3 }
        if timeLeft >= twoStarTimeLeft { return 2 }
        return 1
    }

    static let kitchen = LevelConfig(
        number: 1,
        title: "Kitchen Panic",
        duration: 40,
        quota: 30,
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

    static let all: [LevelConfig] = [kitchen]
}

/// Summary handed from a finished game to the results screen.
struct LevelResult: Equatable {
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

    var totalCoins: Int { bounty + completionBonus + timeBonus }
}
