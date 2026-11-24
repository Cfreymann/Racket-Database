import SwiftUI

struct MenuView: View {
    @EnvironmentObject private var app: AppModel

    var body: some View {
        ZStack {
            KitchenFloor().ignoresSafeArea()
            MenuBugs(showFly: app.unlockedLevel >= 2).ignoresSafeArea().allowsHitTesting(false)

            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    CoinBadge(amount: app.coins)
                }

                Spacer(minLength: 0)

                VStack(spacing: 0) {
                    CartoonText("DEBUGGER", size: 58, fill: Palette.roachRed, strokeWidth: 4)
                    CartoonText("squash 'em fast!", size: 20, fill: .white, strokeWidth: 2.5)
                }
                .rotationEffect(.degrees(-4))

                Mascot()
                    .frame(maxWidth: 190, minHeight: 90, maxHeight: 190)

                VStack(spacing: 14) {
                    ForEach(Array(LevelConfig.all.enumerated()), id: \.offset) { index, level in
                        LevelCard(
                            level: level,
                            stars: app.bestStars[level.number] ?? 0,
                            locked: !app.isUnlocked(level),
                            isNew: index > 0 && app.isUnlocked(level) && (app.bestStars[level.number] ?? 0) == 0
                        ) {
                            app.play(levelIndex: index)
                        }
                    }
                }

                Button("UPGRADES") { app.showShop = true }
                    .buttonStyle(CartoonButtonStyle(color: Palette.swatterBlue))

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
    }
}

/// A tappable level row: tap to play. Locked levels say what unlocks them.
private struct LevelCard: View {
    let level: LevelConfig
    let stars: Int
    let locked: Bool
    let isNew: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                BugIcon(kind: level.icon, size: 42)
                    .opacity(locked ? 0.45 : 1)
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text("LEVEL \(level.number)")
                            .font(.system(size: 13, weight: .heavy, design: .rounded))
                            .foregroundStyle(Palette.roachRed)
                        if isNew { NewTag(text: "NEW") }
                    }
                    Text(level.title)
                        .font(.system(size: 20, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.outline.opacity(locked ? 0.45 : 1))
                    if locked {
                        Text("Clear Level \(level.number - 1) to unlock")
                            .font(.system(size: 13, weight: .bold, design: .rounded))
                            .foregroundStyle(Palette.outline.opacity(0.7))
                    }
                }
                Spacer()
                if locked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 22, weight: .black))
                        .foregroundStyle(Palette.outline)
                } else {
                    StarsRow(stars: stars, size: 20, animate: true)
                }
            }
            .frame(maxWidth: 320)
            .padding(.vertical, -4)
            .cartoonPanel(fill: locked ? Color(red: 0.91, green: 0.88, blue: 0.82) : Palette.cream)
        }
        .buttonStyle(PressDownStyle())
        .disabled(locked)
    }
}

/// Nudges a panel down when pressed, like the cartoon buttons.
private struct PressDownStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .offset(y: configuration.isPressed ? 3 : 0)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

/// The big roach from the reference art, idly wiggling.
private struct Mascot: View {
    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                let bob = CGFloat(sin(t * 2)) * 3
                BugRenderer.draw(ctx, kind: .roach,
                                 at: CGPoint(x: size.width / 2, y: size.height / 2 + 8 + bob),
                                 heading: -.pi / 2 - 0.4 + CGFloat(sin(t * 0.8)) * 0.05,
                                 legPhase: CGFloat(sin(t * 3)) * 0.8,
                                 extraScale: min(size.width, size.height) / 110)
            }
        }
    }
}

/// A few bugs running laps around the menu.
private struct MenuBugs: View {
    let showFly: Bool

    private struct Runner {
        let kind: BugKind
        let ax: CGFloat, ay: CGFloat
        let wx: Double, wy: Double
        let px: Double, py: Double
    }

    private let runners: [Runner] = [
        Runner(kind: .roach, ax: 0.42, ay: 0.44, wx: 0.31, wy: 0.23, px: 0, py: 1.2),
        Runner(kind: .zoomer, ax: 0.45, ay: 0.40, wx: 0.47, wy: 0.35, px: 2.1, py: 0.3),
        Runner(kind: .roach, ax: 0.38, ay: 0.46, wx: 0.21, wy: 0.29, px: 4.0, py: 2.6),
        Runner(kind: .bigRoach, ax: 0.40, ay: 0.42, wx: 0.17, wy: 0.13, px: 1.0, py: 4.4),
        Runner(kind: .fly, ax: 0.44, ay: 0.45, wx: 0.53, wy: 0.41, px: 3.1, py: 1.9),
    ]

    var body: some View {
        TimelineView(.animation) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { ctx, size in
                var c = ctx
                c.opacity = 0.9
                for r in runners where showFly || r.kind != .fly {
                    let x = size.width / 2 + r.ax * size.width * CGFloat(sin(r.wx * t + r.px))
                    let y = size.height / 2 + r.ay * size.height * CGFloat(sin(r.wy * t + r.py))
                    let vx = r.ax * size.width * CGFloat(r.wx * cos(r.wx * t + r.px))
                    let vy = r.ay * size.height * CGFloat(r.wy * cos(r.wy * t + r.py))
                    let speed = hypot(vx, vy)
                    let phase = r.kind.isFlier ? CGFloat(t.truncatingRemainder(dividingBy: 1000)) * 45
                                               : CGFloat(t.truncatingRemainder(dividingBy: 1000)) * (4 + speed * 0.05)
                    BugRenderer.draw(c, kind: r.kind, at: CGPoint(x: x, y: y), heading: atan2(vy, vx), legPhase: phase)
                }
            }
        }
    }
}

struct StarsRow: View {
    let stars: Int
    var size: CGFloat = 40
    var animate: Bool = true

    var body: some View {
        HStack(spacing: size * 0.15) {
            ForEach(0..<3, id: \.self) { i in
                let earned = i < stars
                ZStack {
                    Image(systemName: "star.fill")
                        .font(.system(size: size, weight: .black))
                        .foregroundStyle(earned ? Palette.gold : Palette.locked.opacity(0.45))
                    Image(systemName: "star")
                        .font(.system(size: size, weight: .black))
                        .foregroundStyle(Palette.outline)
                }
                .scaleEffect(animate ? 1 : 0.1)
                .rotationEffect(.degrees(animate ? 0 : -90))
                .offset(y: i == 1 ? -size * 0.15 : 0)
                .animation(.spring(response: 0.45, dampingFraction: 0.5).delay(Double(i) * 0.18), value: animate)
            }
        }
    }
}
