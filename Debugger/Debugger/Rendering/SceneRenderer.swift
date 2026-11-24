import SwiftUI

enum SceneRenderer {
    static func draw(_ scene: GameSceneSnapshot, in ctx: GraphicsContext, size: CGSize) {
        for splat in scene.splats {
            BugRenderer.drawSplat(ctx, splat)
        }
        for bug in scene.bugs {
            BugRenderer.draw(ctx, kind: bug.kind, at: bug.position, heading: bug.heading,
                             legPhase: bug.legPhase, flash: bug.hurtFlash)
        }
        for puff in scene.puffs {
            ToolRenderer.drawPuff(ctx, puff, color: scene.sprayColor)
        }
        for swat in scene.swats {
            ToolRenderer.drawSwat(ctx, swat)
        }
        for whiff in scene.whiffs {
            ToolRenderer.drawWhiff(ctx, whiff)
        }
        if let target = scene.sprayNozzleTarget {
            ToolRenderer.drawHeldSprayCan(ctx, aimingAt: target, color: scene.sprayColor)
        }
        for popup in scene.popups {
            let k = popup.age / Popup.life
            let pop = CGFloat(k < 0.15 ? 0.6 + k / 0.15 * 0.5 : 1.1 - min(0.1, (k - 0.15)))
            drawOutlinedText(ctx, popup.text, at: popup.position, size: popup.size * pop,
                             color: popup.color, opacity: k < 0.6 ? 1 : max(0, 1 - (k - 0.6) / 0.4))
        }
    }

    static func drawOutlinedText(_ ctx: GraphicsContext, _ string: String, at p: CGPoint, size: CGFloat,
                                 color: Color, opacity: Double) {
        var c = ctx
        c.opacity = opacity
        let font = Font.system(size: size, weight: .black, design: .rounded)
        let outline = c.resolve(Text(string).font(font).foregroundStyle(Palette.outline))
        let fill = c.resolve(Text(string).font(font).foregroundStyle(color))
        let o = max(1.5, size * 0.09)
        let offsets: [(CGFloat, CGFloat)] = [(-o, 0), (o, 0), (0, -o), (0, o), (-o, -o), (o, o), (-o, o), (o, -o)]
        for (dx, dy) in offsets {
            c.draw(outline, at: CGPoint(x: p.x + dx, y: p.y + dy))
        }
        c.draw(fill, at: p)
    }
}

/// Static level background: kitchen tiles or a red-and-white picnic blanket.
struct FloorView: View {
    var style: FloorStyle = .kitchen

    var body: some View {
        switch style {
        case .kitchen: KitchenFloor()
        case .picnic: PicnicBlanket()
        }
    }
}

struct PicnicBlanket: View {
    var body: some View {
        Canvas { ctx, size in
            let full = CGRect(origin: .zero, size: size)
            ctx.fill(Path(full), with: .color(Color(red: 1.0, green: 0.97, blue: 0.925)))

            let band: CGFloat = 36
            var stripes = Path()
            var x: CGFloat = 0
            while x < size.width + band {
                stripes.addRect(CGRect(x: x, y: 0, width: band, height: size.height))
                x += band * 2
            }
            ctx.fill(stripes, with: .color(Color(red: 0.84, green: 0.20, blue: 0.17).opacity(0.42)))
            var rows = Path()
            var y: CGFloat = 0
            while y < size.height + band {
                rows.addRect(CGRect(x: 0, y: y, width: size.width, height: band))
                y += band * 2
            }
            ctx.fill(rows, with: .color(Color(red: 0.84, green: 0.20, blue: 0.17).opacity(0.42)))

            // Woven texture.
            var weave = Path()
            var line: CGFloat = 0
            while line < size.height {
                weave.move(to: CGPoint(x: 0, y: line))
                weave.addLine(to: CGPoint(x: size.width, y: line))
                line += 6
            }
            ctx.stroke(weave, with: .color(Color(red: 0.63, green: 0.12, blue: 0.10).opacity(0.18)), lineWidth: 1)

            // Bun crumbs (deterministic).
            var crumbs = Path()
            var seed: UInt64 = 777
            func next() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat((seed >> 33) % 10_000) / 10_000
            }
            for _ in 0..<30 {
                let r = 1.5 + next() * 3
                crumbs.addEllipse(in: CGRect(x: next() * size.width, y: next() * size.height, width: r * 2, height: r * 1.5))
            }
            ctx.fill(crumbs, with: .color(Color(red: 0.71, green: 0.51, blue: 0.25)))

            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            ctx.fill(Path(full), with: .radialGradient(
                Gradient(colors: [.clear, Palette.outline.opacity(0.2)]),
                center: center, startRadius: min(size.width, size.height) * 0.35,
                endRadius: max(size.width, size.height) * 0.75))
        }
    }
}

/// Static cartoon kitchen-tile floor.
struct KitchenFloor: View {
    var body: some View {
        Canvas { ctx, size in
            let full = CGRect(origin: .zero, size: size)
            ctx.fill(Path(full), with: .color(Palette.tileB))

            let tile: CGFloat = 64
            let cols = Int(ceil(size.width / tile)) + 1
            let rows = Int(ceil(size.height / tile)) + 1
            var light = Path()
            var grout = Path()
            for row in 0..<rows {
                for col in 0..<cols where (row + col) % 2 == 0 {
                    light.addRect(CGRect(x: CGFloat(col) * tile, y: CGFloat(row) * tile, width: tile, height: tile))
                }
                grout.move(to: CGPoint(x: 0, y: CGFloat(row) * tile))
                grout.addLine(to: CGPoint(x: size.width, y: CGFloat(row) * tile))
            }
            for col in 0..<cols {
                grout.move(to: CGPoint(x: CGFloat(col) * tile, y: 0))
                grout.addLine(to: CGPoint(x: CGFloat(col) * tile, y: size.height))
            }
            ctx.fill(light, with: .color(Palette.tileA))
            ctx.stroke(grout, with: .color(Palette.grout), lineWidth: 2)

            // A few crumbs (deterministic so they don't jump around).
            var crumbs = Path()
            var seed: UInt64 = 12345
            func next() -> CGFloat {
                seed = seed &* 6364136223846793005 &+ 1442695040888963407
                return CGFloat((seed >> 33) % 10_000) / 10_000
            }
            for _ in 0..<26 {
                let x = next() * size.width
                let y = next() * size.height
                let r = 1.5 + next() * 2.5
                crumbs.addEllipse(in: CGRect(x: x, y: y, width: r * 2, height: r * 1.6))
            }
            ctx.fill(crumbs, with: .color(Palette.crumb))

            // Soft vignette for depth.
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            ctx.fill(Path(full), with: .radialGradient(
                Gradient(colors: [.clear, Palette.outline.opacity(0.18)]),
                center: center, startRadius: min(size.width, size.height) * 0.35,
                endRadius: max(size.width, size.height) * 0.75))
        }
    }
}
