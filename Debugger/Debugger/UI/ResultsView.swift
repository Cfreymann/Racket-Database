import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var app: AppModel
    let result: LevelResult
    @State private var appeared = false

    var body: some View {
        let level = app.level(at: result.levelIndex)
        let hasNext = result.levelIndex + 1 < LevelConfig.all.count
        ZStack {
            FloorView(style: level.floor).ignoresSafeArea()
            Color.black.opacity(0.25).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    CartoonText("LEVEL CLEAR!", size: 44, fill: Palette.gold, strokeWidth: 4)
                        .rotationEffect(.degrees(-3))
                        .scaleEffect(appeared ? 1 : 0.5)
                        .padding(.top, 12)

                    StarsRow(stars: result.stars, size: 46, animate: appeared)

                    if let unlocked = result.unlockedLevelNumber {
                        let next = LevelConfig.all[unlocked - 1]
                        let sprayNote = unlocked == LevelConfig.sprayUnlockLevel ? " Bug Spray is now available in the shop." : ""
                        let message: String = "Level \(unlocked) unlocked: \(next.title)!" + sprayNote
                        Text(message)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                            .foregroundStyle(Palette.outline)
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: 340)
                            .cartoonPanel(fill: Palette.gold)
                    }

                    VStack(spacing: 10) {
                        StatRow(label: "Bugs squashed", value: "\(result.kills) / \(result.quota)")
                        StatRow(label: "Got away", value: "\(result.escaped)")
                        StatRow(label: "Best combo", value: result.bestCombo >= 2 ? "x\(result.bestCombo)" : "-")
                        StatRow(label: "Time left", value: "\(Int(result.timeLeft))s")
                    }
                    .frame(maxWidth: 340)
                    .cartoonPanel()

                    VStack(spacing: 10) {
                        CoinRow(label: "Bug bounties", amount: result.bounty)
                        CoinRow(label: "Level complete", amount: result.completionBonus)
                        CoinRow(label: "Speed bonus", amount: result.timeBonus)
                        Rectangle().fill(Palette.outline.opacity(0.2)).frame(height: 2)
                        HStack {
                            Text("TOTAL")
                                .font(.system(size: 20, weight: .black, design: .rounded))
                            Spacer()
                            CoinIcon(size: 26)
                            Text("+\(result.totalCoins)")
                                .font(.system(size: 26, weight: .black, design: .rounded))
                                .monospacedDigit()
                        }
                        .foregroundStyle(Palette.outline)
                    }
                    .frame(maxWidth: 340)
                    .cartoonPanel()

                    VStack(spacing: 16) {
                        Button {
                            app.showShop = true
                        } label: {
                            HStack(spacing: 8) {
                                Text("UPGRADES")
                                CoinIcon(size: 22)
                                Text("\(app.coins)").monospacedDigit()
                            }
                        }
                        .buttonStyle(CartoonButtonStyle(color: Palette.swatterBlue))

                        if hasNext {
                            Button("NEXT LEVEL") { app.play(levelIndex: result.levelIndex + 1) }
                                .buttonStyle(CartoonButtonStyle(color: Palette.sprayGreen))
                        } else {
                            Button {} label: {
                                VStack(spacing: 0) {
                                    Text("NEXT LEVEL")
                                    Text("coming soon")
                                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                                }
                            }
                            .buttonStyle(CartoonButtonStyle(color: Palette.locked))
                            .disabled(true)
                        }

                        Button("PLAY AGAIN") { app.play(levelIndex: result.levelIndex) }
                            .buttonStyle(CartoonButtonStyle(color: Palette.gold))

                        Button("MENU") { app.goToMenu() }
                            .buttonStyle(CartoonButtonStyle(color: Palette.roachRed, minWidth: 160, fontSize: 20))
                    }
                    .padding(.top, 6)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.15)) {
                appeared = true
            }
        }
    }
}

private struct StatRow: View {
    let label: String
    let value: String

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .bold, design: .rounded))
            Spacer()
            Text(value)
                .font(.system(size: 19, weight: .black, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(Palette.outline)
    }
}

private struct CoinRow: View {
    let label: String
    let amount: Int

    var body: some View {
        HStack {
            Text(label)
                .font(.system(size: 17, weight: .bold, design: .rounded))
            Spacer()
            CoinIcon(size: 18)
            Text("+\(amount)")
                .font(.system(size: 19, weight: .black, design: .rounded))
                .monospacedDigit()
        }
        .foregroundStyle(Palette.outline)
    }
}
