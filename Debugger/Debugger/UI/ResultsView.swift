import SwiftUI

struct ResultsView: View {
    @EnvironmentObject private var app: AppModel
    let result: LevelResult
    @State private var appeared = false

    var body: some View {
        ZStack {
            KitchenFloor().ignoresSafeArea()
            Color.black.opacity(0.25).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    CartoonText(result.won ? "LEVEL CLEAR!" : "TIME'S UP!", size: 44,
                                fill: result.won ? Palette.gold : Palette.roachRed, strokeWidth: 4)
                        .rotationEffect(.degrees(-3))
                        .scaleEffect(appeared ? 1 : 0.5)
                        .padding(.top, 12)

                    StarsRow(stars: result.stars, size: 46, animate: appeared)

                    VStack(spacing: 10) {
                        StatRow(label: "Bugs squashed", value: "\(result.kills) / \(result.quota)")
                        StatRow(label: "Got away", value: "\(result.escaped)")
                        StatRow(label: "Best combo", value: result.bestCombo >= 2 ? "x\(result.bestCombo)" : "-")
                        if result.won {
                            StatRow(label: "Time left", value: "\(Int(result.timeLeft))s")
                        }
                    }
                    .frame(maxWidth: 340)
                    .cartoonPanel()

                    VStack(spacing: 10) {
                        CoinRow(label: "Bug bounties", amount: result.bounty)
                        if result.won {
                            CoinRow(label: "Level complete", amount: result.completionBonus)
                            CoinRow(label: "Speed bonus", amount: result.timeBonus)
                        }
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
                        if !result.won {
                            Text("Spend your bounty on upgrades and try again!")
                                .font(.system(size: 14, weight: .bold, design: .rounded))
                                .foregroundStyle(Palette.roachRed)
                                .multilineTextAlignment(.center)
                        }
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

                        Button(result.won ? "PLAY AGAIN" : "TRY AGAIN") { app.playCurrentLevel() }
                            .buttonStyle(CartoonButtonStyle(color: Palette.sprayGreen))

                        if result.won {
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
