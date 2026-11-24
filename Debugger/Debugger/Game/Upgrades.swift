import SwiftUI

enum UpgradeKind: CaseIterable, Identifiable {
    case swatter, spray

    var id: Self { self }

    var title: String {
        switch self {
        case .swatter: "FLY SWATTER"
        case .spray: "BUG SPRAY"
        }
    }
}

/// One tier of fly swatter. Tapping the screen swats everything inside `radius`,
/// then the swatter needs `cooldown` seconds to recharge before it can swat again.
struct SwatterStats {
    let name: String
    let radius: CGFloat
    let damage: Double
    let cooldown: Double
    let color: Color

    static let tiers: [SwatterStats] = [
        SwatterStats(name: "Rolled-Up Newspaper", radius: 38, damage: 1.0, cooldown: 0.55, color: Color(red: 0.86, green: 0.84, blue: 0.78)),
        SwatterStats(name: "Plastic Swatter", radius: 46, damage: 1.5, cooldown: 0.45, color: Color(red: 0.22, green: 0.56, blue: 0.95)),
        SwatterStats(name: "Wire Mesh Swatter", radius: 54, damage: 2.0, cooldown: 0.36, color: Color(red: 0.93, green: 0.35, blue: 0.27)),
        SwatterStats(name: "Double Swatter", radius: 64, damage: 3.0, cooldown: 0.28, color: Color(red: 0.58, green: 0.36, blue: 0.86)),
        SwatterStats(name: "Mega Swatter 9000", radius: 76, damage: 4.0, cooldown: 0.20, color: Color(red: 1.00, green: 0.76, blue: 0.16)),
    ]

    /// `upgradeCosts[i]` buys tier `i + 1`.
    static let upgradeCosts = [60, 150, 300, 550]
}

/// One tier of bug spray. Dragging a finger sprays a poison mist that damages bugs over time.
struct SprayStats {
    let name: String
    /// Seconds of continuous spraying on a full can.
    let tank: Double
    /// Damage per second to a bug standing in the mist.
    let dps: Double
    let cloudRadius: CGFloat
    /// Tank seconds regained per second while not spraying.
    let refill: Double
    let color: Color

    static let tiers: [SprayStats] = [
        SprayStats(name: "Old Spray Can", tank: 2.5, dps: 1.2, cloudRadius: 34, refill: 0.35, color: Color(red: 0.45, green: 0.78, blue: 0.30)),
        SprayStats(name: "Bug-B-Gone", tank: 3.5, dps: 1.6, cloudRadius: 40, refill: 0.45, color: Color(red: 0.30, green: 0.75, blue: 0.55)),
        SprayStats(name: "Toxic Mist", tank: 4.5, dps: 2.1, cloudRadius: 46, refill: 0.55, color: Color(red: 0.62, green: 0.80, blue: 0.18)),
        SprayStats(name: "Fog Blaster", tank: 6.0, dps: 2.8, cloudRadius: 54, refill: 0.70, color: Color(red: 0.25, green: 0.70, blue: 0.80)),
        SprayStats(name: "Nuclear Nozzle", tank: 8.0, dps: 3.6, cloudRadius: 62, refill: 0.90, color: Color(red: 0.75, green: 0.95, blue: 0.20)),
    ]

    static let upgradeCosts = [80, 180, 350, 600]
}
