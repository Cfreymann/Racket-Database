import SwiftUI

struct GameView: View {
    @StateObject private var engine: GameEngine
    @Environment(\.scenePhase) private var scenePhase
    private let onQuit: () -> Void

    init(level: LevelConfig, swatter: SwatterStats, spray: SprayStats,
         onFinish: @escaping (LevelResult) -> Void, onQuit: @escaping () -> Void) {
        _engine = StateObject(wrappedValue: GameEngine(level: level, swatter: swatter, spray: spray, onFinish: onFinish))
        self.onQuit = onQuit
    }

    var body: some View {
        ZStack {
            KitchenFloor().ignoresSafeArea()

            GeometryReader { geo in
                TimelineView(.animation(minimumInterval: nil, paused: engine.phase == .paused)) { _ in
                    let scene = engine.snapshot()
                    Canvas { ctx, size in
                        SceneRenderer.draw(scene, in: ctx, size: size)
                    }
                }
                .contentShape(Rectangle())
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .local)
                        .onChanged { value in engine.drag(at: value.location) }
                        .onEnded { _ in engine.dragEnded() }
                )
                .onAppear { engine.start(size: geo.size) }
                .onChange(of: geo.size) { _, newSize in engine.size = newSize }
            }
            .ignoresSafeArea()

            HUDView(engine: engine)

            overlay
        }
        .onDisappear { engine.stop() }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active { engine.pause() }
        }
    }

    @ViewBuilder
    private var overlay: some View {
        switch engine.phase {
        case .countdown:
            CountdownOverlay(level: engine.level, count: Int(ceil(engine.countdown)))
                .allowsHitTesting(false)
        case .playing:
            if engine.elapsed < 0.7 {
                Banner(text: "SWAT!", color: Palette.gold, progress: engine.elapsed / 0.7)
                    .allowsHitTesting(false)
            }
        case .paused:
            PauseOverlay(
                resume: { engine.resume() },
                quit: {
                    engine.stop()
                    onQuit()
                }
            )
        case .won:
            Banner(text: "SQUASHED!", color: Palette.sprayGreen, progress: 0.5)
                .allowsHitTesting(false)
        case .lost:
            Banner(text: "TIME'S UP!", color: Palette.roachRed, progress: 0.5)
                .allowsHitTesting(false)
        }
    }
}

// MARK: - HUD

private struct HUDView: View {
    @ObservedObject var engine: GameEngine

    var body: some View {
        VStack(spacing: 10) {
            HStack(alignment: .center) {
                Button { engine.pause() } label: {
                    Image(systemName: "pause.fill")
                        .font(.system(size: 18, weight: .black))
                        .foregroundStyle(.white)
                        .frame(width: 44, height: 44)
                        .background(Circle().fill(Palette.roachRed))
                        .overlay(Circle().stroke(Palette.outline, lineWidth: 3))
                }
                Spacer()
                TimerPill(timeLeft: engine.timeLeft)
                    .allowsHitTesting(false)
                Spacer()
                CoinBadge(amount: engine.bounty)
                    .allowsHitTesting(false)
            }

            QuotaBar(kills: engine.kills, quota: engine.level.quota)
                .allowsHitTesting(false)

            Spacer()

            HStack(alignment: .bottom) {
                if engine.phase == .playing && engine.elapsed < 7 {
                    ControlsHint()
                        .transition(.opacity)
                }
                Spacer()
                SprayMeter(fraction: engine.sprayFraction, active: engine.isSpraying, color: engine.spray.color)
            }
            .allowsHitTesting(false)
        }
        .padding(.horizontal, 16)
        .padding(.top, 6)
        .padding(.bottom, 10)
    }
}

private struct TimerPill: View {
    let timeLeft: Double

    var body: some View {
        let urgent = timeLeft <= 10
        HStack(spacing: 6) {
            Image(systemName: "stopwatch.fill")
                .font(.system(size: 18, weight: .black))
            Text("\(Int(ceil(timeLeft)))")
                .font(.system(size: 26, weight: .black, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(urgent ? .white : Palette.outline)
        .padding(.horizontal, 16)
        .padding(.vertical, 5)
        .background(Capsule().fill(urgent ? Palette.roachRed : Palette.cream))
        .overlay(Capsule().stroke(Palette.outline, lineWidth: 3))
        .scaleEffect(urgent ? 1 + 0.06 * CGFloat(max(0, sin(timeLeft * .pi * 2))) : 1)
    }
}

private struct QuotaBar: View {
    let kills: Int
    let quota: Int

    var body: some View {
        let fraction = min(1, CGFloat(kills) / CGFloat(max(1, quota)))
        HStack(spacing: 8) {
            BugIcon(size: 30)
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(Palette.cream)
                    Capsule()
                        .fill(Palette.sprayGreen)
                        .frame(width: max(0, geo.size.width * fraction))
                        .animation(.spring(response: 0.25, dampingFraction: 0.7), value: kills)
                    Capsule().stroke(Palette.outline, lineWidth: 3)
                    Text("\(kills) / \(quota)")
                        .font(.system(size: 15, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.outline)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 24)
        }
    }
}

private struct SprayMeter: View {
    let fraction: Double
    let active: Bool
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .bottom) {
                Capsule().fill(Palette.cream)
                Capsule()
                    .fill(fraction < 0.15 ? Palette.roachRed : color)
                    .frame(height: 96 * CGFloat(fraction))
                Capsule().stroke(Palette.outline, lineWidth: 3)
            }
            .frame(width: 22, height: 96)
            SprayCanIcon(color: color, size: 44)
                .scaleEffect(active ? 1.15 : 1)
        }
    }
}

private struct ControlsHint: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Label("Tap to SWAT", systemImage: "hand.tap.fill")
            Label("Drag to SPRAY", systemImage: "hand.draw.fill")
        }
        .font(.system(size: 15, weight: .heavy, design: .rounded))
        .foregroundStyle(Palette.outline)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.cream.opacity(0.92)))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Palette.outline, lineWidth: 3))
    }
}

// MARK: - Overlays

private struct CountdownOverlay: View {
    let level: LevelConfig
    let count: Int

    var body: some View {
        ZStack {
            Color.black.opacity(0.35).ignoresSafeArea()
            VStack(spacing: 18) {
                VStack(spacing: 6) {
                    Text("LEVEL \(level.number)")
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.roachRed)
                    Text(level.title)
                        .font(.system(size: 30, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.outline)
                    Text(level.objective)
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.outline.opacity(0.8))
                        .multilineTextAlignment(.center)
                    HStack(spacing: 16) {
                        Label("Tap = swat", systemImage: "hand.tap.fill")
                        Label("Drag = spray", systemImage: "hand.draw.fill")
                    }
                    .font(.system(size: 14, weight: .heavy, design: .rounded))
                    .foregroundStyle(Palette.roachRed)
                    .padding(.top, 4)
                }
                .frame(maxWidth: 320)
                .cartoonPanel()

                CartoonText("\(max(1, count))", size: 110, fill: Palette.gold, strokeWidth: 5)
                    .id(count)
                    .transition(.scale(scale: 2).combined(with: .opacity))
            }
            .padding(.horizontal, 24)
            .animation(.spring(response: 0.3, dampingFraction: 0.55), value: count)
        }
    }
}

private struct Banner: View {
    let text: String
    let color: Color
    /// 0...1, drives a quick pop-in.
    let progress: Double

    var body: some View {
        let pop = progress < 0.3 ? 0.6 + progress / 0.3 * 0.5 : 1.1 - min(0.1, (progress - 0.3) * 0.3)
        CartoonText(text, size: 64, fill: color, strokeWidth: 5)
            .rotationEffect(.degrees(-6))
            .scaleEffect(pop)
            .shadow(color: .black.opacity(0.25), radius: 0, x: 0, y: 6)
    }
}

private struct PauseOverlay: View {
    let resume: () -> Void
    let quit: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.45).ignoresSafeArea()
            VStack(spacing: 18) {
                CartoonText("PAUSED", size: 48, fill: .white, strokeWidth: 4)
                Button("RESUME", action: resume)
                    .buttonStyle(CartoonButtonStyle(color: Palette.sprayGreen))
                Button("QUIT TO MENU", action: quit)
                    .buttonStyle(CartoonButtonStyle(color: Palette.roachRed))
            }
        }
    }
}
