import SwiftUI

struct BugColors {
    let legs: Color
    let body: Color
    let pronotum: Color
    let head: Color
    let stripe: Color
}

enum BugKind: CaseIterable {
    /// The classic red-brown roach from the style reference.
    case roach
    /// Slow, tanky, worth more.
    case bigRoach
    /// Small, tan and very fast.
    case zoomer

    var displayName: String {
        switch self {
        case .roach: "Roach"
        case .bigRoach: "Big Momma"
        case .zoomer: "Zoomer"
        }
    }

    var maxHP: Double {
        switch self {
        case .roach: 1
        case .bigRoach: 3
        case .zoomer: 1
        }
    }

    var speedRange: ClosedRange<CGFloat> {
        switch self {
        case .roach: 70...105
        case .bigRoach: 45...65
        case .zoomer: 150...190
        }
    }

    var scale: CGFloat {
        switch self {
        case .roach: 1.0
        case .bigRoach: 1.4
        case .zoomer: 0.78
        }
    }

    var reward: Int {
        switch self {
        case .roach: 5
        case .bigRoach: 15
        case .zoomer: 10
        }
    }

    /// How long the bug scurries around before it tries to escape off-screen.
    var lifetimeRange: ClosedRange<Double> {
        switch self {
        case .roach: 6...9
        case .bigRoach: 9...12
        case .zoomer: 4...6
        }
    }

    /// Radians per second.
    var turnRate: CGFloat {
        switch self {
        case .roach: 4
        case .bigRoach: 2.5
        case .zoomer: 6
        }
    }

    /// Chance a roach freezes for a moment when it changes direction (very roach-like).
    var pauseChance: Double {
        switch self {
        case .roach: 0.25
        case .bigRoach: 0.15
        case .zoomer: 0.35
        }
    }

    var colors: BugColors {
        switch self {
        case .roach:
            BugColors(legs: Palette.roachRed, body: Palette.roachBody, pronotum: Palette.roachRed,
                      head: Palette.roachHead, stripe: Palette.roachStripe)
        case .bigRoach:
            BugColors(legs: Color(red: 0.55, green: 0.16, blue: 0.10),
                      body: Color(red: 0.27, green: 0.10, blue: 0.07),
                      pronotum: Color(red: 0.52, green: 0.15, blue: 0.10),
                      head: Color(red: 0.20, green: 0.07, blue: 0.05),
                      stripe: Color(red: 0.18, green: 0.06, blue: 0.04))
        case .zoomer:
            BugColors(legs: Color(red: 0.80, green: 0.47, blue: 0.20),
                      body: Color(red: 0.56, green: 0.33, blue: 0.15),
                      pronotum: Color(red: 0.84, green: 0.56, blue: 0.27),
                      head: Color(red: 0.42, green: 0.23, blue: 0.10),
                      stripe: Color(red: 0.42, green: 0.23, blue: 0.10))
        }
    }
}

struct Bug: Identifiable {
    let id: Int
    let kind: BugKind
    var position: CGPoint
    /// Direction of travel in radians (0 = moving right, .pi/2 = moving down).
    var heading: CGFloat
    var targetHeading: CGFloat
    var baseSpeed: CGFloat
    var hp: Double
    let lifetime: Double
    var age: Double = 0
    var legPhase: CGFloat = 0
    var hurtFlash: Double = 0
    var wanderTimer: Double = 0.5
    var pauseTimer: Double = 0
    var panic: Double = 0
    var hasEntered = false
    var isLeaving = false
    var inMist = false

    var radius: CGFloat { 24 * kind.scale }
}

struct Splat {
    let kind: BugKind
    let position: CGPoint
    let heading: CGFloat
    /// Goo blobs, relative to `position`.
    let blobs: [CGRect]
    var age: Double = 0

    static let life: Double = 4.0
}

struct SwatEffect {
    let position: CGPoint
    let radius: CGFloat
    let color: Color
    let tilt: CGFloat
    var age: Double = 0

    static let duration: Double = 0.25
}

struct MistPuff {
    var position: CGPoint
    var velocity: CGVector
    let maxRadius: CGFloat
    let life: Double
    var age: Double = 0

    var radius: CGFloat { maxRadius * CGFloat(0.45 + 0.55 * min(1, age / 0.25)) }
    var alpha: Double { max(0, 1 - age / life) }
}

struct Popup {
    let text: String
    var position: CGPoint
    let color: Color
    let size: CGFloat
    var age: Double = 0

    static let life: Double = 0.9
}
