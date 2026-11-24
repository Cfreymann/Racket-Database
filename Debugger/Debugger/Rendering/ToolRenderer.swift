import SwiftUI

/// Draws the fly swatter and bug spray can, plus their in-game effects.
enum ToolRenderer {
    // MARK: Swatter

    /// Swatter head centered at the origin with the handle pointing down (+y).
    static func drawSwatter(_ c: GraphicsContext, radius r: CGFloat, color: Color, handleLength: CGFloat = 80) {
        var handle = Path()
        handle.move(to: CGPoint(x: 0, y: r * 0.9))
        handle.addLine(to: CGPoint(x: 0, y: r * 0.9 + handleLength))
        c.stroke(handle, with: .color(Palette.outline), style: StrokeStyle(lineWidth: 11, lineCap: .round))
        c.stroke(handle, with: .color(color), style: StrokeStyle(lineWidth: 6, lineCap: .round))

        let headRect = CGRect(x: -r, y: -r, width: 2 * r, height: 2 * r)
        let head = Path(roundedRect: headRect, cornerRadius: r * 0.35)
        c.fill(head, with: .color(color.opacity(0.88)))

        var mesh = Path()
        let step = r / 3
        var offset = -r + step
        while offset < r - 1 {
            mesh.move(to: CGPoint(x: offset, y: -r))
            mesh.addLine(to: CGPoint(x: offset, y: r))
            mesh.move(to: CGPoint(x: -r, y: offset))
            mesh.addLine(to: CGPoint(x: r, y: offset))
            offset += step
        }
        var clipped = c
        clipped.clip(to: head)
        clipped.stroke(mesh, with: .color(.white.opacity(0.45)), lineWidth: 1.5)
        c.stroke(head, with: .color(Palette.outline), lineWidth: 3.5)
    }

    static func drawSwat(_ ctx: GraphicsContext, _ swat: SwatEffect) {
        let k = min(1, swat.age / SwatEffect.duration)

        // Impact ring.
        let ringR = swat.radius * CGFloat(0.7 + 0.6 * k)
        let ring = Path(ellipseIn: CGRect(x: swat.position.x - ringR, y: swat.position.y - ringR,
                                          width: ringR * 2, height: ringR * 2))
        ctx.stroke(ring, with: .color(.white.opacity(0.85 * (1 - k))), lineWidth: 4)

        // The swatter slamming down.
        var c = ctx
        c.opacity = 1 - k * k
        c.translateBy(x: swat.position.x, y: swat.position.y)
        c.rotate(by: .radians(Double(swat.tilt)))
        let slam = CGFloat(1.35 - 0.35 * min(1, k * 4))
        c.scaleBy(x: slam, y: slam)
        drawSwatter(c, radius: swat.radius, color: swat.color)
    }

    /// A tap while the swatter is recharging: a small dashed "not yet" ring.
    static func drawWhiff(_ ctx: GraphicsContext, _ whiff: Whiff) {
        let k = min(1, whiff.age / Whiff.duration)
        let r = CGFloat(14 + k * 10)
        var c = ctx
        c.opacity = 1 - k
        let ring = Path(ellipseIn: CGRect(x: whiff.position.x - r, y: whiff.position.y - r, width: r * 2, height: r * 2))
        c.stroke(ring, with: .color(Palette.outline.opacity(0.6)), style: StrokeStyle(lineWidth: 3, dash: [5, 5]))
    }

    // MARK: Spray can

    /// Can centered at the origin with the nozzle pointing up (-y), about 30x80pt.
    static func drawSprayCan(_ c: GraphicsContext, color: Color) {
        let outline = Palette.outline

        let nozzle = Path(roundedRect: CGRect(x: -3.5, y: -45, width: 7, height: 9), cornerRadius: 2)
        c.fill(nozzle, with: .color(Color(white: 0.3)))
        c.stroke(nozzle, with: .color(outline), lineWidth: 2)

        let cap = Path(roundedRect: CGRect(x: -10, y: -38, width: 20, height: 13), cornerRadius: 5)
        c.fill(cap, with: .color(Color(white: 0.85)))
        c.stroke(cap, with: .color(outline), lineWidth: 2.5)

        let body = Path(roundedRect: CGRect(x: -15, y: -28, width: 30, height: 60), cornerRadius: 8)
        c.fill(body, with: .color(color))

        var label = c
        label.clip(to: body)
        label.fill(Path(CGRect(x: -15, y: -10, width: 30, height: 20)), with: .color(.white))
        // A tiny crossed-out roach on the label.
        var mini = label
        mini.scaleBy(x: 0.2, y: 0.2)
        BugRenderer.drawRoach(mini, colors: BugKind.roach.colors, legPhase: 0, splayed: false, flash: 0)
        var slash = Path()
        slash.move(to: CGPoint(x: -8, y: 7))
        slash.addLine(to: CGPoint(x: 8, y: -7))
        label.stroke(slash, with: .color(Palette.roachRed), style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
        // Shine.
        label.fill(Path(roundedRect: CGRect(x: -11, y: -24, width: 5, height: 50), cornerRadius: 2.5),
                   with: .color(.white.opacity(0.3)))

        c.stroke(body, with: .color(outline), lineWidth: 3)
    }

    /// The can held just below-right of the finger, nozzle aimed at it.
    static func drawHeldSprayCan(_ ctx: GraphicsContext, aimingAt target: CGPoint, color: Color) {
        var c = ctx
        let offset = CGPoint(x: 40, y: 58)
        c.translateBy(x: target.x + offset.x, y: target.y + offset.y)
        let angle = atan2(-offset.y, -offset.x)
        c.rotate(by: .radians(Double(angle) + .pi / 2))
        drawSprayCan(c, color: color)
    }

    static func drawPuff(_ ctx: GraphicsContext, _ puff: MistPuff, color: Color) {
        let r = puff.radius
        let rect = CGRect(x: puff.position.x - r, y: puff.position.y - r, width: r * 2, height: r * 2)
        let a = puff.alpha
        ctx.fill(Path(ellipseIn: rect), with: .radialGradient(
            Gradient(colors: [color.opacity(0.55 * a), color.opacity(0.35 * a), color.opacity(0)]),
            center: puff.position, startRadius: 0, endRadius: r))
    }
}
