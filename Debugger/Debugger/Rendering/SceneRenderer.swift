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
