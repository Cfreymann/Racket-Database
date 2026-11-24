import SwiftUI

/// Shown when time runs out. The bounty is kept and the level restarts automatically
/// after a countdown; the player can restart right away, upgrade first, or quit.
struct FailView: View {
    @EnvironmentObject private var app: AppModel
    let result: LevelResult
    @State private var remaining = AppModel.restartSeconds

    var body: some View {
        let level = app.level(at: result.levelIndex)
        ZStack {
            FloorView(style: level.floor).ignoresSafeArea()
            Color.black.opacity(0.42).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 16) {
                    CartoonText("TIME'S UP!", size: 54, fill: Palette.roachRed, strokeWidth: 4)
                        .rotationEffect(.degrees(-3))
                        .padding(.top, 24)

                    VStack(spacing: 8) {
                        Text("You squashed \(result.kills) of \(result.quota) bugs.")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                        HStack(spacing: 6) {
                            Text("Bounty kept:")
                            CoinIcon(size: 22)
                            Text("+\(result.bounty)").monospacedDigit()
                        }
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    }
                    .foregroundStyle(Palette.outline)
                    .frame(maxWidth: 340)
                    .cartoonPanel()

                    ZStack {
                        Circle().stroke(Color.white.opacity(0.25), lineWidth: 10)
                        Circle()
                            .trim(from: 0, to: CGFloat(max(0, remaining) / AppModel.restartSeconds))
                            .stroke(Palette.gold, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.1), value: remaining)
                        CartoonText("\(Int(ceil(max(0, remaining))))", size: 64, fill: Palette.gold, strokeWidth: 4)
                    }
                    .frame(width: 120, height: 120)

                    Text("RESTARTING LEVEL")
                        .font(.system(size: 14, weight: .black, design: .rounded))
                        .tracking(1.2)
                        .foregroundStyle(.white)
                        .shadow(color: Palette.outline, radius: 0, x: 0, y: 2)

                    VStack(spacing: 16) {
                        Button("RESTART NOW") { app.restartLevel() }
                            .buttonStyle(CartoonButtonStyle(color: Palette.sprayGreen))
                        Button("UPGRADE FIRST") { app.openShopThenRestart() }
                            .buttonStyle(CartoonButtonStyle(color: Palette.swatterBlue))
                        Button("MENU") { app.goToMenu() }
                            .buttonStyle(CartoonButtonStyle(color: Palette.roachRed, minWidth: 160, fontSize: 20))
                    }
                    .padding(.top, 4)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }
        }
        .task {
            // Count down while this screen is up; the shop pauses it.
            while remaining > 0 {
                try? await Task.sleep(nanoseconds: 100_000_000)
                if Task.isCancelled { return }
                if !app.showShop { remaining -= 0.1 }
            }
            if case .failed = app.screen, !app.showShop {
                app.restartLevel()
            }
        }
    }
}
