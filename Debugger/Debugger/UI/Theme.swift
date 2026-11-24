import SwiftUI

/// Colors pulled from the cartoon roach reference: dark outlines, brick-red, deep brown.
enum Palette {
    static let outline = Color(red: 0.16, green: 0.10, blue: 0.08)
    static let roachRed = Color(red: 0.65, green: 0.20, blue: 0.13)
    static let roachBody = Color(red: 0.36, green: 0.14, blue: 0.09)
    static let roachHead = Color(red: 0.30, green: 0.11, blue: 0.08)
    static let roachStripe = Color(red: 0.26, green: 0.09, blue: 0.06)

    static let cream = Color(red: 1.00, green: 0.97, blue: 0.89)
    static let tileA = Color(red: 0.99, green: 0.95, blue: 0.84)
    static let tileB = Color(red: 0.94, green: 0.87, blue: 0.71)
    static let grout = Color(red: 0.84, green: 0.75, blue: 0.58)
    static let crumb = Color(red: 0.76, green: 0.58, blue: 0.33)

    static let goo = Color(red: 0.80, green: 0.85, blue: 0.32)
    static let gooOutline = Color(red: 0.42, green: 0.48, blue: 0.10)

    static let gold = Color(red: 1.00, green: 0.78, blue: 0.15)
    static let sprayGreen = Color(red: 0.38, green: 0.74, blue: 0.26)
    static let swatterBlue = Color(red: 0.22, green: 0.56, blue: 0.95)
    static let locked = Color(red: 0.62, green: 0.58, blue: 0.54)
}

/// Chunky rounded text with a dark cartoon outline.
struct CartoonText: View {
    let text: String
    var size: CGFloat = 32
    var fill: Color = .white
    var stroke: Color = Palette.outline
    var strokeWidth: CGFloat = 3

    init(_ text: String, size: CGFloat = 32, fill: Color = .white, stroke: Color = Palette.outline, strokeWidth: CGFloat = 3) {
        self.text = text
        self.size = size
        self.fill = fill
        self.stroke = stroke
        self.strokeWidth = strokeWidth
    }

    var body: some View {
        let base = Text(text).font(.system(size: size, weight: .black, design: .rounded))
        ZStack {
            ForEach(0..<8, id: \.self) { i in
                let angle = CGFloat(i) / 8 * 2 * .pi
                base.foregroundStyle(stroke)
                    .offset(x: cos(angle) * strokeWidth, y: sin(angle) * strokeWidth)
            }
            base.foregroundStyle(fill)
        }
        .fixedSize()
    }
}

struct CartoonButtonStyle: ButtonStyle {
    var color: Color = Palette.roachRed
    var minWidth: CGFloat = 240
    var fontSize: CGFloat = 24

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 22, style: .continuous)
        return configuration.label
            .font(.system(size: fontSize, weight: .black, design: .rounded))
            .foregroundStyle(.white)
            .shadow(color: Palette.outline.opacity(0.6), radius: 0, x: 0, y: 2)
            .padding(.horizontal, 24)
            .padding(.vertical, 13)
            .frame(minWidth: minWidth)
            .background(shape.fill(color))
            .overlay(shape.stroke(Palette.outline, lineWidth: 4))
            .offset(y: configuration.isPressed ? 4 : 0)
            .background(shape.fill(Palette.outline).offset(y: 6))
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .animation(.spring(response: 0.2, dampingFraction: 0.6), value: configuration.isPressed)
    }
}

struct CartoonPanel: ViewModifier {
    var fill: Color = Palette.cream

    func body(content: Content) -> some View {
        let shape = RoundedRectangle(cornerRadius: 24, style: .continuous)
        return content
            .padding(18)
            .background(shape.fill(fill))
            .overlay(shape.stroke(Palette.outline, lineWidth: 4))
            .background(shape.fill(Palette.outline).offset(y: 6))
    }
}

extension View {
    func cartoonPanel(fill: Color = Palette.cream) -> some View {
        modifier(CartoonPanel(fill: fill))
    }
}

struct CoinIcon: View {
    var size: CGFloat = 22

    var body: some View {
        ZStack {
            Circle().fill(Palette.gold)
            Circle().stroke(Palette.outline, lineWidth: max(2, size * 0.11))
            Circle().inset(by: size * 0.22).stroke(Color.white.opacity(0.5), lineWidth: max(1, size * 0.06))
            Text("$")
                .font(.system(size: size * 0.55, weight: .black, design: .rounded))
                .foregroundStyle(Palette.outline.opacity(0.75))
        }
        .frame(width: size, height: size)
    }
}

struct CoinBadge: View {
    let amount: Int

    var body: some View {
        HStack(spacing: 6) {
            CoinIcon(size: 24)
            Text("\(amount)")
                .font(.system(size: 20, weight: .black, design: .rounded))
                .foregroundStyle(Palette.outline)
                .monospacedDigit()
                .contentTransition(.numericText())
        }
        .padding(.leading, 6)
        .padding(.trailing, 14)
        .padding(.vertical, 5)
        .background(Capsule().fill(Palette.cream))
        .overlay(Capsule().stroke(Palette.outline, lineWidth: 3))
    }
}

/// Small static roach icon for HUD and cards.
struct BugIcon: View {
    var kind: BugKind = .roach
    var size: CGFloat = 28
    var heading: CGFloat = -.pi / 2 - 0.35

    var body: some View {
        Canvas { ctx, canvasSize in
            let scale = size / (100 * kind.scale)
            BugRenderer.draw(ctx, kind: kind, at: CGPoint(x: canvasSize.width / 2, y: canvasSize.height / 2 + size * 0.1),
                             heading: heading, legPhase: 0.8, extraScale: scale)
        }
        .frame(width: size, height: size)
    }
}

struct SwatterIcon: View {
    var color: Color
    var size: CGFloat = 56

    var body: some View {
        Canvas { ctx, canvasSize in
            var c = ctx
            c.translateBy(x: canvasSize.width * 0.42, y: canvasSize.height * 0.36)
            c.rotate(by: .radians(-0.6))
            let r = size * 0.27
            ToolRenderer.drawSwatter(c, radius: r, color: color, handleLength: size * 0.32)
        }
        .frame(width: size, height: size)
    }
}

struct SprayCanIcon: View {
    var color: Color
    var size: CGFloat = 56

    var body: some View {
        Canvas { ctx, canvasSize in
            var c = ctx
            c.translateBy(x: canvasSize.width / 2, y: canvasSize.height / 2 + size * 0.04)
            c.rotate(by: .radians(0.25))
            let s = size / 95
            c.scaleBy(x: s, y: s)
            ToolRenderer.drawSprayCan(c, color: color)
        }
        .frame(width: size, height: size)
    }
}
