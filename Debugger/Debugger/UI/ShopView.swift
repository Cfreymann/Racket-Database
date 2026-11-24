import SwiftUI
import UIKit

struct ShopView: View {
    @EnvironmentObject private var app: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirmReset = false

    var body: some View {
        ZStack {
            Palette.tileA.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 22) {
                    HStack {
                        CartoonText("UPGRADES", size: 38, fill: Palette.swatterBlue, strokeWidth: 3.5)
                        Spacer()
                        CoinBadge(amount: app.coins)
                    }
                    .padding(.top, 20)

                    UpgradeCard(kind: .swatter)
                    UpgradeCard(kind: .spray)

                    Button("DONE") { dismiss() }
                        .buttonStyle(CartoonButtonStyle(color: Palette.sprayGreen))
                        .padding(.top, 4)

                    Button("Reset progress") { confirmReset = true }
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                        .foregroundStyle(Palette.outline.opacity(0.5))
                        .padding(.top, 10)
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 30)
            }
        }
        .confirmationDialog("Reset all coins and upgrades?", isPresented: $confirmReset, titleVisibility: .visible) {
            Button("Reset", role: .destructive) { app.resetProgress() }
        }
    }
}

private struct UpgradeCard: View {
    @EnvironmentObject private var app: AppModel
    let kind: UpgradeKind

    private struct StatLine: Identifiable {
        let label: String
        let current: String
        let next: String?
        var id: String { label }
    }

    var body: some View {
        let tier = app.tier(of: kind)
        let maxTier = app.maxTier(of: kind)
        let cost = app.nextCost(of: kind)

        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 14) {
                icon(tier: tier)
                    .frame(width: 64, height: 64)
                    .background(Circle().fill(Color.white))
                    .overlay(Circle().stroke(Palette.outline, lineWidth: 3))
                VStack(alignment: .leading, spacing: 3) {
                    Text(kind.title)
                        .font(.system(size: 13, weight: .heavy, design: .rounded))
                        .foregroundStyle(Palette.roachRed)
                    Text(tierName(tier))
                        .font(.system(size: 21, weight: .black, design: .rounded))
                        .foregroundStyle(Palette.outline)
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    TierPips(tier: tier, maxTier: maxTier)
                }
                Spacer(minLength: 0)
            }

            VStack(spacing: 6) {
                ForEach(stats(tier: tier)) { line in
                    HStack {
                        Text(line.label)
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Spacer()
                        Text(line.current)
                            .font(.system(size: 16, weight: .black, design: .rounded))
                        if let next = line.next {
                            Image(systemName: "arrow.right")
                                .font(.system(size: 12, weight: .black))
                            Text(next)
                                .font(.system(size: 16, weight: .black, design: .rounded))
                                .foregroundStyle(Palette.sprayGreen)
                        }
                    }
                    .foregroundStyle(Palette.outline)
                    .monospacedDigit()
                }
            }

            if let cost {
                Button {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) { app.buy(kind) }
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                } label: {
                    HStack(spacing: 8) {
                        Text("UPGRADE")
                        CoinIcon(size: 22)
                        Text("\(cost)").monospacedDigit()
                    }
                }
                .buttonStyle(CartoonButtonStyle(color: app.canBuy(kind) ? Palette.sprayGreen : Palette.locked,
                                                minWidth: 0, fontSize: 20))
                .frame(maxWidth: .infinity)
                .disabled(!app.canBuy(kind))
            } else {
                Text("MAXED OUT!")
                    .font(.system(size: 20, weight: .black, design: .rounded))
                    .foregroundStyle(Palette.gold)
                    .shadow(color: Palette.outline, radius: 0, x: 1, y: 1)
                    .frame(maxWidth: .infinity)
            }
        }
        .cartoonPanel(fill: Palette.cream)
    }

    @ViewBuilder
    private func icon(tier: Int) -> some View {
        switch kind {
        case .swatter: SwatterIcon(color: SwatterStats.tiers[tier].color, size: 56)
        case .spray: SprayCanIcon(color: SprayStats.tiers[tier].color, size: 56)
        }
    }

    private func tierName(_ tier: Int) -> String {
        switch kind {
        case .swatter: SwatterStats.tiers[tier].name
        case .spray: SprayStats.tiers[tier].name
        }
    }

    private func stats(tier: Int) -> [StatLine] {
        switch kind {
        case .swatter:
            let now = SwatterStats.tiers[tier]
            let next = tier + 1 < SwatterStats.tiers.count ? SwatterStats.tiers[tier + 1] : nil
            return [
                StatLine(label: "Swat size", current: "\(Int(now.radius))", next: next.map { "\(Int($0.radius))" }),
                StatLine(label: "Swat power", current: format(now.damage), next: next.map { format($0.damage) }),
            ]
        case .spray:
            let now = SprayStats.tiers[tier]
            let next = tier + 1 < SprayStats.tiers.count ? SprayStats.tiers[tier + 1] : nil
            return [
                StatLine(label: "Tank (sec)", current: format(now.tank), next: next.map { format($0.tank) }),
                StatLine(label: "Potency", current: format(now.dps), next: next.map { format($0.dps) }),
                StatLine(label: "Cloud size", current: "\(Int(now.cloudRadius))", next: next.map { "\(Int($0.cloudRadius))" }),
            ]
        }
    }

    private func format(_ value: Double) -> String {
        String(format: "%.1f", value)
    }
}

private struct TierPips: View {
    let tier: Int
    let maxTier: Int

    var body: some View {
        HStack(spacing: 5) {
            ForEach(0...maxTier, id: \.self) { i in
                Capsule()
                    .fill(i <= tier ? Palette.gold : Palette.locked.opacity(0.35))
                    .overlay(Capsule().stroke(Palette.outline, lineWidth: 2))
                    .frame(width: 22, height: 10)
            }
        }
    }
}
