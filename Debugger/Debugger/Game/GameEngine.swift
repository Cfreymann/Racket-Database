import SwiftUI
import UIKit

enum GamePhase: Equatable {
    case countdown, playing, paused, won, lost
}

/// Everything the renderer needs for one frame, copied out of the engine.
struct GameSceneSnapshot {
    var bugs: [Bug]
    var splats: [Splat]
    var swats: [SwatEffect]
    var puffs: [MistPuff]
    var popups: [Popup]
    var sprayNozzleTarget: CGPoint?
    var sprayColor: Color
}

/// Runs one level: spawning, bug movement, swatting, spraying, scoring.
/// Ticked by a CADisplayLink; publishes a change every frame so the HUD stays live.
@MainActor
final class GameEngine: ObservableObject {
    let level: LevelConfig
    let swatter: SwatterStats
    let spray: SprayStats

    private(set) var phase: GamePhase = .countdown
    private(set) var countdown: Double = 3.0
    private(set) var timeLeft: Double
    private(set) var elapsed: Double = 0
    private(set) var kills = 0
    private(set) var escaped = 0
    private(set) var bounty = 0
    private(set) var combo = 0
    private(set) var bestCombo = 0
    private(set) var sprayTank: Double
    private(set) var isSpraying = false

    var size: CGSize = .zero

    private var bugs: [Bug] = []
    private var splats: [Splat] = []
    private var swats: [SwatEffect] = []
    private var puffs: [MistPuff] = []
    private var popups: [Popup] = []

    private var nextBugID = 0
    private var spawnTimer: Double = 0.3
    private var lastKillTime: Double = -10
    private var touchStart: CGPoint?
    private var touchPoint: CGPoint?
    private var puffTimer: Double = 0
    private var sprayIdle: Double = 0
    private var finishTimer: Double = 0
    private var reported = false
    private var phaseBeforePause: GamePhase = .playing

    private let onFinish: (LevelResult) -> Void
    private lazy var displayLink = DisplayLink { [weak self] dt in self?.tick(dt) }
    private let swatHaptic = UIImpactFeedbackGenerator(style: .light)
    private let killHaptic = UIImpactFeedbackGenerator(style: .heavy)

    init(level: LevelConfig, swatter: SwatterStats, spray: SprayStats, onFinish: @escaping (LevelResult) -> Void) {
        self.level = level
        self.swatter = swatter
        self.spray = spray
        self.onFinish = onFinish
        self.timeLeft = level.duration
        self.sprayTank = spray.tank
    }

    var sprayFraction: Double { spray.tank > 0 ? sprayTank / spray.tank : 0 }

    // MARK: - Lifecycle

    func start(size: CGSize) {
        self.size = size
        swatHaptic.prepare()
        killHaptic.prepare()
        displayLink.start()
    }

    func stop() {
        displayLink.stop()
    }

    func pause() {
        guard phase == .playing || phase == .countdown else { return }
        phaseBeforePause = phase
        phase = .paused
        dragEnded()
        objectWillChange.send()
    }

    func resume() {
        guard phase == .paused else { return }
        phase = phaseBeforePause
        objectWillChange.send()
    }

    func snapshot() -> GameSceneSnapshot {
        GameSceneSnapshot(
            bugs: bugs,
            splats: splats,
            swats: swats,
            puffs: puffs,
            popups: popups,
            sprayNozzleTarget: (isSpraying && phase == .playing) ? touchPoint : nil,
            sprayColor: spray.color
        )
    }

    // MARK: - Input

    /// Feed every DragGesture change here. The first contact swats; dragging sprays.
    func drag(at point: CGPoint) {
        if touchStart == nil {
            touchStart = point
            touchPoint = point
            isSpraying = false
            swat(at: point)
        } else {
            touchPoint = point
            if !isSpraying, let start = touchStart, hypot(point.x - start.x, point.y - start.y) > 18 {
                isSpraying = true
                puffTimer = 0
            }
        }
    }

    func dragEnded() {
        touchStart = nil
        touchPoint = nil
        isSpraying = false
    }

    private func swat(at point: CGPoint) {
        guard phase == .playing else { return }
        swats.append(SwatEffect(position: point, radius: swatter.radius, color: swatter.color,
                                tilt: .random(in: -0.7 ... -0.3)))
        swatHaptic.impactOccurred()

        var killed: [Int] = []
        for i in bugs.indices {
            let bug = bugs[i]
            let distance = hypot(bug.position.x - point.x, bug.position.y - point.y)
            guard distance < swatter.radius + bug.radius * 0.5 else { continue }
            bugs[i].hp -= swatter.damage
            bugs[i].hurtFlash = 1
            bugs[i].pauseTimer = 0
            bugs[i].panic = 0.8
            // Scatter away from the swat.
            bugs[i].targetHeading = atan2(bug.position.y - point.y, bug.position.x - point.x)
            if bugs[i].hp <= 0 { killed.append(i) }
        }
        for i in killed.reversed() {
            registerKill(bugs.remove(at: i))
        }
    }

    // MARK: - Frame update

    private func tick(_ dt: Double) {
        switch phase {
        case .paused:
            return
        case .countdown:
            countdown -= dt
            if countdown <= 0 {
                phase = .playing
            }
        case .playing:
            elapsed += dt
            timeLeft = max(0, timeLeft - dt)
            updateSpawning(dt)
            updateSpray(dt)
            updateBugs(dt)
            applyMistDamage(dt)
            updateEffects(dt)
            if kills >= level.quota {
                finish(won: true)
            } else if timeLeft <= 0 {
                finish(won: false)
            }
        case .won, .lost:
            updateBugs(dt)
            updateEffects(dt)
            finishTimer += dt
            if finishTimer > 1.6 && !reported {
                reported = true
                stop()
                onFinish(makeResult())
            }
        }
        objectWillChange.send()
    }

    private func updateSpawning(_ dt: Double) {
        spawnTimer -= dt
        guard spawnTimer <= 0 else { return }
        let progress = min(1, elapsed / level.duration)
        let interval = level.spawnIntervalStart + (level.spawnIntervalEnd - level.spawnIntervalStart) * progress
        spawnTimer = interval * Double.random(in: 0.7...1.3)

        let active = bugs.filter { !$0.isLeaving }.count
        guard active < level.maxAlive else { return }
        let count = (progress > 0.5 && Double.random(in: 0...1) < 0.3) ? 2 : 1
        for _ in 0..<count { spawnBug() }
    }

    private func pickKind() -> BugKind {
        let options = level.spawnRules.filter { elapsed >= $0.after }
        let total = options.reduce(0) { $0 + $1.weight }
        guard total > 0 else { return .roach }
        var roll = Double.random(in: 0..<total)
        for option in options {
            if roll < option.weight { return option.kind }
            roll -= option.weight
        }
        return .roach
    }

    private func spawnBug() {
        let kind = pickKind()
        let w = size.width
        let h = size.height
        let margin: CGFloat = 40
        let position: CGPoint
        switch Int.random(in: 0..<4) {
        case 0: position = CGPoint(x: CGFloat.random(in: 0...w), y: -margin)
        case 1: position = CGPoint(x: w + margin, y: CGFloat.random(in: 0...h))
        case 2: position = CGPoint(x: CGFloat.random(in: 0...w), y: h + margin)
        default: position = CGPoint(x: -margin, y: CGFloat.random(in: 0...h))
        }
        let target = CGPoint(x: CGFloat.random(in: (w * 0.25)...(w * 0.75)),
                             y: CGFloat.random(in: (h * 0.25)...(h * 0.75)))
        let heading = atan2(target.y - position.y, target.x - position.x)
        bugs.append(Bug(
            id: nextBugID,
            kind: kind,
            position: position,
            heading: heading,
            targetHeading: heading,
            baseSpeed: CGFloat.random(in: kind.speedRange),
            hp: kind.maxHP,
            lifetime: Double.random(in: kind.lifetimeRange)
        ))
        nextBugID += 1
    }

    private func updateBugs(_ dt: Double) {
        let w = size.width
        let h = size.height
        let fdt = CGFloat(dt)
        let center = CGPoint(x: w / 2, y: h / 2)
        var survivors: [Bug] = []
        survivors.reserveCapacity(bugs.count)

        for var bug in bugs {
            bug.age += dt
            bug.hurtFlash = max(0, bug.hurtFlash - dt * 4)
            bug.panic = max(0, bug.panic - dt)

            let inside = bug.position.x > 0 && bug.position.x < w && bug.position.y > 0 && bug.position.y < h
            if inside { bug.hasEntered = true }
            if !bug.isLeaving && bug.age > bug.lifetime {
                bug.isLeaving = true
                bug.targetHeading = headingToNearestEdge(from: bug.position)
            }

            if bug.pauseTimer > 0 {
                bug.pauseTimer -= dt
            } else {
                bug.wanderTimer -= dt
                if bug.wanderTimer <= 0 {
                    bug.wanderTimer = Double.random(in: 0.4...1.2)
                    if bug.isLeaving {
                        bug.targetHeading = headingToNearestEdge(from: bug.position) + CGFloat.random(in: -0.3...0.3)
                    } else if bug.panic <= 0 {
                        bug.targetHeading = bug.heading + CGFloat.random(in: -1.0...1.0)
                        if Double.random(in: 0...1) < bug.kind.pauseChance {
                            bug.pauseTimer = Double.random(in: 0.25...0.6)
                        }
                    }
                }

                // Until it decides to leave, a bug stays on the kitchen floor.
                if !bug.isLeaving {
                    let inward = atan2(center.y - bug.position.y, center.x - bug.position.x)
                    let edge: CGFloat = 26
                    let nearEdge = bug.position.x < edge || bug.position.x > w - edge
                        || bug.position.y < edge || bug.position.y > h - edge
                    if (!bug.hasEntered || nearEdge) && abs(angleDiff(bug.targetHeading, inward)) > 1.1 {
                        bug.targetHeading = inward
                    }
                }

                let diff = angleDiff(bug.targetHeading, bug.heading)
                let maxTurn = bug.kind.turnRate * (bug.panic > 0 ? 2 : 1) * fdt
                bug.heading += max(-maxTurn, min(maxTurn, diff))

                var speed = bug.baseSpeed
                if bug.isLeaving { speed *= 1.3 }
                if bug.panic > 0 { speed *= 1.6 }
                if bug.inMist { speed *= 0.6 }
                bug.position.x += cos(bug.heading) * speed * fdt
                bug.position.y += sin(bug.heading) * speed * fdt
                bug.legPhase += speed * fdt * 0.22
            }

            let out: CGFloat = 60
            let gone = bug.position.x < -out || bug.position.x > w + out
                || bug.position.y < -out || bug.position.y > h + out
            if gone && (bug.hasEntered || bug.isLeaving) {
                if phase == .playing { escaped += 1 }
                continue
            }
            survivors.append(bug)
        }
        bugs = survivors
    }

    private func updateSpray(_ dt: Double) {
        if isSpraying, let point = touchPoint, sprayTank > 0 {
            sprayTank = max(0, sprayTank - dt)
            sprayIdle = 0
            puffTimer -= dt
            if puffTimer <= 0 {
                puffTimer = 0.035
                let jitter = CGPoint(x: CGFloat.random(in: -6...6), y: CGFloat.random(in: -6...6))
                puffs.append(MistPuff(
                    position: CGPoint(x: point.x + jitter.x, y: point.y + jitter.y),
                    velocity: CGVector(dx: CGFloat.random(in: -25...25), dy: CGFloat.random(in: -25...25)),
                    maxRadius: spray.cloudRadius * CGFloat.random(in: 0.75...1.0),
                    life: 1.1
                ))
            }
        } else {
            sprayIdle += dt
            if sprayIdle > 0.6 {
                sprayTank = min(spray.tank, sprayTank + spray.refill * dt)
            }
        }
    }

    private func applyMistDamage(_ dt: Double) {
        var killed: [Int] = []
        for i in bugs.indices {
            var hit = false
            for puff in puffs where puff.age < puff.life * 0.85 {
                let distance = hypot(bugs[i].position.x - puff.position.x, bugs[i].position.y - puff.position.y)
                if distance < puff.radius + bugs[i].radius * 0.5 {
                    hit = true
                    break
                }
            }
            bugs[i].inMist = hit
            if hit {
                bugs[i].hp -= spray.dps * dt
                bugs[i].hurtFlash = max(bugs[i].hurtFlash, 0.35)
                if bugs[i].hp <= 0 { killed.append(i) }
            }
        }
        for i in killed.reversed() {
            registerKill(bugs.remove(at: i))
        }
    }

    private func updateEffects(_ dt: Double) {
        swats = swats.compactMap { swat in
            var s = swat
            s.age += dt
            return s.age < SwatEffect.duration ? s : nil
        }
        let fdt = CGFloat(dt)
        puffs = puffs.compactMap { puff in
            var p = puff
            p.age += dt
            p.position.x += p.velocity.dx * fdt
            p.position.y += p.velocity.dy * fdt
            p.velocity.dx *= 0.96
            p.velocity.dy *= 0.96
            return p.age < p.life ? p : nil
        }
        popups = popups.compactMap { popup in
            var p = popup
            p.age += dt
            p.position.y -= 45 * fdt
            return p.age < Popup.life ? p : nil
        }
        splats = splats.compactMap { splat in
            var s = splat
            s.age += dt
            return s.age < Splat.life ? s : nil
        }
    }

    // MARK: - Scoring

    private func registerKill(_ bug: Bug) {
        kills += 1
        combo = (elapsed - lastKillTime < 0.9) ? combo + 1 : 1
        lastKillTime = elapsed
        bestCombo = max(bestCombo, combo)

        let comboBonus = combo >= 2 ? (combo - 1) * 2 : 0
        let reward = bug.kind.reward + comboBonus
        bounty += reward

        var blobs: [CGRect] = []
        let gooSize = 30 * bug.kind.scale
        for _ in 0..<7 {
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let distance = CGFloat.random(in: 0...(gooSize * 0.7))
            let r = CGFloat.random(in: (gooSize * 0.25)...(gooSize * 0.55))
            blobs.append(CGRect(x: cos(angle) * distance - r, y: sin(angle) * distance - r, width: r * 2, height: r * 2))
        }
        splats.append(Splat(kind: bug.kind, position: bug.position, heading: bug.heading, blobs: blobs))
        if splats.count > 40 { splats.removeFirst(splats.count - 40) }

        popups.append(Popup(text: "+\(reward)", position: bug.position, color: Palette.gold, size: 22))
        if combo >= 3 {
            popups.append(Popup(text: "COMBO x\(combo)!",
                                position: CGPoint(x: bug.position.x, y: bug.position.y - 30),
                                color: Palette.sprayGreen, size: 26))
        }
        killHaptic.impactOccurred()
    }

    private func finish(won: Bool) {
        phase = won ? .won : .lost
        dragEnded()
        // Survivors scatter off-screen.
        for i in bugs.indices {
            bugs[i].isLeaving = true
            bugs[i].pauseTimer = 0
            bugs[i].panic = 2
            bugs[i].targetHeading = headingToNearestEdge(from: bugs[i].position)
        }
        if won {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
        }
    }

    private func makeResult() -> LevelResult {
        let won = phase == .won
        return LevelResult(
            levelNumber: level.number,
            levelTitle: level.title,
            won: won,
            kills: kills,
            quota: level.quota,
            escaped: escaped,
            bestCombo: bestCombo,
            timeLeft: timeLeft,
            bounty: bounty,
            completionBonus: won ? level.completionBonus : 0,
            timeBonus: won ? Int(timeLeft) * level.timeBonusPerSecond : 0,
            stars: won ? level.stars(timeLeft: timeLeft) : 0
        )
    }

    // MARK: - Geometry helpers

    private func headingToNearestEdge(from p: CGPoint) -> CGFloat {
        let distances: [(CGFloat, CGFloat)] = [
            (p.x, .pi),                         // left
            (size.width - p.x, 0),              // right
            (p.y, -.pi / 2),                    // top
            (size.height - p.y, .pi / 2),       // bottom
        ]
        return distances.min { $0.0 < $1.0 }?.1 ?? 0
    }

    private func angleDiff(_ a: CGFloat, _ b: CGFloat) -> CGFloat {
        var d = (a - b).truncatingRemainder(dividingBy: 2 * .pi)
        if d > .pi { d -= 2 * .pi }
        if d < -.pi { d += 2 * .pi }
        return d
    }
}
