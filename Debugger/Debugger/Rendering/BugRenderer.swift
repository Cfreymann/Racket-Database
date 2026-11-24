import SwiftUI

/// Draws the cartoon cockroach in code, styled after the reference art:
/// thick dark outline, red-orange legs/antennae/pronotum, dark-brown oval body
/// with a darker center stripe.
///
/// Local coordinates: the bug faces up (-y), centered roughly on its middle.
/// At scale 1 it's about 70pt wide and 100pt tall including antennae.
enum BugRenderer {
    private struct LegSpec {
        let attach: CGPoint
        let knee: CGPoint
        let foot: CGPoint
        let phaseOffset: CGFloat
    }

    /// Right-hand legs. Left legs are mirrored with the opposite gait phase (tripod gait).
    private static let rightLegs: [LegSpec] = [
        LegSpec(attach: CGPoint(x: 9, y: -12), knee: CGPoint(x: 26, y: -20), foot: CGPoint(x: 22, y: -36), phaseOffset: 0),
        LegSpec(attach: CGPoint(x: 11, y: 1), knee: CGPoint(x: 30, y: -2), foot: CGPoint(x: 36, y: 12), phaseOffset: .pi),
        LegSpec(attach: CGPoint(x: 11, y: 11), knee: CGPoint(x: 28, y: 18), foot: CGPoint(x: 30, y: 40), phaseOffset: 0),
    ]

    static func draw(_ ctx: GraphicsContext, kind: BugKind, at position: CGPoint, heading: CGFloat,
                     legPhase: CGFloat, flash: Double = 0, extraScale: CGFloat = 1) {
        var c = ctx
        c.translateBy(x: position.x, y: position.y)
        c.rotate(by: .radians(Double(heading) + .pi / 2))
        let s = kind.scale * extraScale
        c.scaleBy(x: s, y: s)
        drawCritter(c, kind: kind, legPhase: legPhase, splayed: false, flash: flash)
    }

    /// Draws any bug type in local coordinates (facing up).
    static func drawCritter(_ c: GraphicsContext, kind: BugKind, legPhase: CGFloat, splayed: Bool, flash: Double) {
        if kind.isFlier {
            drawFly(c, colors: kind.colors, legPhase: legPhase, splayed: splayed, flash: flash)
        } else {
            drawRoach(c, colors: kind.colors, legPhase: legPhase, splayed: splayed, flash: flash)
        }
    }

    static func drawSplat(_ ctx: GraphicsContext, _ splat: Splat) {
        var c = ctx
        let fadeStart = Splat.life - 1.5
        c.opacity = splat.age < fadeStart ? 1 : max(0, 1 - (splat.age - fadeStart) / 1.5)
        c.translateBy(x: splat.position.x, y: splat.position.y)

        var goo = Path()
        for blob in splat.blobs { goo.addEllipse(in: blob) }
        // Outline trick: stroke wide in a dark color, then fill on top, so overlapping
        // blobs read as one cartoon puddle with no inner lines.
        c.stroke(goo, with: .color(Palette.gooOutline), lineWidth: 5)
        c.fill(goo, with: .color(Palette.goo))

        // The flattened bug itself.
        var bug = c
        bug.rotate(by: .radians(Double(splat.heading) + .pi / 2))
        let s = splat.kind.scale
        bug.scaleBy(x: s * 1.2, y: s * 0.8)
        drawCritter(bug, kind: splat.kind, legPhase: 0, splayed: true, flash: 0)

        // Cartoon "X X" eyes.
        var eyes = c
        eyes.rotate(by: .radians(Double(splat.heading) + .pi / 2))
        eyes.scaleBy(x: s * 1.2, y: s * 0.8)
        var cross = Path()
        let eyeY: CGFloat = splat.kind.isFlier ? -22 : -28
        let eyeX: CGFloat = splat.kind.isFlier ? 6 : 4
        for x in [-eyeX, eyeX] {
            cross.move(to: CGPoint(x: x - 2.2, y: eyeY - 2.2)); cross.addLine(to: CGPoint(x: x + 2.2, y: eyeY + 2.2))
            cross.move(to: CGPoint(x: x + 2.2, y: eyeY - 2.2)); cross.addLine(to: CGPoint(x: x - 2.2, y: eyeY + 2.2))
        }
        eyes.stroke(cross, with: .color(.white), style: StrokeStyle(lineWidth: 1.6, lineCap: .round))
    }

    static func drawRoach(_ c: GraphicsContext, colors: BugColors, legPhase: CGFloat, splayed: Bool, flash: Double) {
        let outline = Palette.outline

        // Legs (under the body).
        var legsPath = Path()
        for spec in rightLegs {
            for side in [1, -1] as [CGFloat] {
                let phase = legPhase + spec.phaseOffset + (side < 0 ? .pi : 0)
                let swing: CGFloat = splayed ? 0 : sin(phase) * 0.32
                let spread: CGFloat = splayed ? 1.18 : 1
                let attach = CGPoint(x: spec.attach.x * side, y: spec.attach.y)
                let knee = rotate(CGPoint(x: spec.knee.x * side * spread, y: spec.knee.y), around: attach, by: swing * side)
                let foot = rotate(CGPoint(x: spec.foot.x * side * spread, y: spec.foot.y), around: attach, by: swing * side)
                legsPath.move(to: attach)
                legsPath.addQuadCurve(to: foot, control: knee)
            }
        }
        c.stroke(legsPath, with: .color(outline), style: StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round))
        c.stroke(legsPath, with: .color(colors.legs), style: StrokeStyle(lineWidth: 3.2, lineCap: .round, lineJoin: .round))

        // Antennae: long sweeping curves like the reference.
        let wiggle: CGFloat = splayed ? 0 : sin(legPhase * 0.5) * 4
        var antennae = Path()
        antennae.move(to: CGPoint(x: 4, y: -30))
        antennae.addQuadCurve(to: CGPoint(x: 30 + wiggle, y: -66), control: CGPoint(x: 6, y: -60))
        antennae.move(to: CGPoint(x: -4, y: -30))
        antennae.addQuadCurve(to: CGPoint(x: -30 + wiggle, y: -64), control: CGPoint(x: -6, y: -58))
        c.stroke(antennae, with: .color(outline), style: StrokeStyle(lineWidth: 4.5, lineCap: .round))
        c.stroke(antennae, with: .color(colors.legs), style: StrokeStyle(lineWidth: 2.2, lineCap: .round))

        // Head (peeks out above the pronotum).
        let head = Path(ellipseIn: CGRect(x: -9.5, y: -35, width: 19, height: 14))
        c.fill(head, with: .color(colors.head))
        c.stroke(head, with: .color(outline), lineWidth: 2.2)
        if !splayed {
            var eyes = Path()
            eyes.addEllipse(in: CGRect(x: -5, y: -32, width: 2.4, height: 2.4))
            eyes.addEllipse(in: CGRect(x: 2.6, y: -32, width: 2.4, height: 2.4))
            c.fill(eyes, with: .color(outline))
        }

        // Abdomen / wings: long dark oval.
        let abdomen = Path(ellipseIn: CGRect(x: -14, y: -12, width: 28, height: 46))
        c.fill(abdomen, with: .color(colors.body))
        c.stroke(abdomen, with: .color(outline), lineWidth: 2.4)

        // Wing seam: a darker sliver down the middle.
        var stripeCtx = c
        stripeCtx.translateBy(x: 1.5, y: 14)
        stripeCtx.rotate(by: .radians(-0.08))
        stripeCtx.fill(Path(ellipseIn: CGRect(x: -1.8, y: -14, width: 3.6, height: 30)), with: .color(colors.stripe))

        // Pronotum: big red shield over the top of the body.
        let pronotum = Path(ellipseIn: CGRect(x: -15.5, y: -27, width: 31, height: 23))
        c.fill(pronotum, with: .color(colors.pronotum))
        c.stroke(pronotum, with: .color(outline), lineWidth: 2.4)
        // Little cartoon shine.
        c.fill(Path(ellipseIn: CGRect(x: -9, y: -23, width: 8, height: 4.5)), with: .color(.white.opacity(0.28)))
        c.fill(Path(ellipseIn: CGRect(x: -9, y: -6, width: 5, height: 12)), with: .color(.white.opacity(0.12)))

        if flash > 0 {
            var hurt = Path()
            hurt.addPath(abdomen)
            hurt.addPath(pronotum)
            c.fill(hurt, with: .color(.white.opacity(min(0.75, flash * 0.75))))
        }
    }

    // MARK: - House fly

    private struct FlyLeg {
        let attach: CGPoint
        let knee: CGPoint
        let foot: CGPoint
    }

    private static let flyLegs: [FlyLeg] = [
        FlyLeg(attach: CGPoint(x: 5, y: -8), knee: CGPoint(x: 14, y: -12), foot: CGPoint(x: 16, y: -22)),
        FlyLeg(attach: CGPoint(x: 6, y: -3), knee: CGPoint(x: 17, y: -2), foot: CGPoint(x: 22, y: 4)),
        FlyLeg(attach: CGPoint(x: 5, y: 2), knee: CGPoint(x: 14, y: 8), foot: CGPoint(x: 17, y: 18)),
    ]

    /// House fly facing up: big red eyes, striped grey abdomen, see-through buzzing wings.
    /// `legPhase` advances quickly for flies and drives the wing buzz.
    static func drawFly(_ c: GraphicsContext, colors: BugColors, legPhase: CGFloat, splayed: Bool, flash: Double) {
        let outline = Palette.outline

        var legs = Path()
        for leg in flyLegs {
            for side in [1, -1] as [CGFloat] {
                let spread: CGFloat = splayed ? 1.25 : 1
                let jiggle: CGFloat = splayed ? 0 : sin(legPhase * 0.3 + leg.attach.y) * 1.2
                legs.move(to: CGPoint(x: leg.attach.x * side, y: leg.attach.y))
                legs.addQuadCurve(to: CGPoint(x: leg.foot.x * side * spread, y: leg.foot.y + jiggle),
                                  control: CGPoint(x: leg.knee.x * side * spread, y: leg.knee.y + jiggle))
            }
        }
        c.stroke(legs, with: .color(outline), style: StrokeStyle(lineWidth: 4, lineCap: .round, lineJoin: .round))
        c.stroke(legs, with: .color(colors.legs), style: StrokeStyle(lineWidth: 1.8, lineCap: .round, lineJoin: .round))

        let abdomen = Path(ellipseIn: CGRect(x: -10, y: -4, width: 20, height: 26))
        c.fill(abdomen, with: .color(colors.body))
        var striped = c
        striped.clip(to: abdomen)
        striped.fill(Path(CGRect(x: -12, y: 5, width: 24, height: 3.5)), with: .color(colors.stripe))
        striped.fill(Path(CGRect(x: -12, y: 12, width: 24, height: 3.5)), with: .color(colors.stripe))
        c.stroke(abdomen, with: .color(outline), lineWidth: 2.4)

        let thorax = Path(ellipseIn: CGRect(x: -9.5, y: -15, width: 19, height: 16))
        c.fill(thorax, with: .color(colors.pronotum))
        c.stroke(thorax, with: .color(outline), lineWidth: 2.4)
        c.fill(Path(ellipseIn: CGRect(x: -5, y: -12, width: 4, height: 9)), with: .color(.white.opacity(0.15)))

        let head = Path(ellipseIn: CGRect(x: -7, y: -25, width: 14, height: 11))
        c.fill(head, with: .color(colors.head))
        c.stroke(head, with: .color(outline), lineWidth: 2.4)
        for side in [1, -1] as [CGFloat] {
            let eye = Path(ellipseIn: CGRect(x: side > 0 ? 0.5 : -11.5, y: -28, width: 11, height: 12))
            c.fill(eye, with: .color(colors.eye))
            c.stroke(eye, with: .color(outline), lineWidth: 2.2)
            if !splayed {
                c.fill(Path(ellipseIn: CGRect(x: side > 0 ? 3 : -9, y: -26, width: 3.5, height: 3)),
                       with: .color(.white.opacity(0.7)))
            }
        }

        // Wings buzz by fanning out and stretching.
        let buzz: CGFloat = splayed ? 0.5 : abs(sin(legPhase * 1.7))
        for side in [1, -1] as [CGFloat] {
            var wing = c
            wing.translateBy(x: 3.5 * side, y: -10)
            wing.rotate(by: .radians(Double(side * (0.45 + buzz * 0.35))))
            wing.scaleBy(x: 1, y: 0.85 + buzz * 0.2)
            let shape = Path(ellipseIn: CGRect(x: -6, y: 0, width: 12, height: 28))
            wing.fill(shape, with: .color(Color(red: 0.88, green: 0.93, blue: 1.0).opacity(0.62)))
            wing.stroke(shape, with: .color(outline), lineWidth: 1.8)
            var veins = Path()
            veins.move(to: CGPoint(x: 0, y: 3)); veins.addLine(to: CGPoint(x: 0, y: 24))
            veins.move(to: CGPoint(x: 0, y: 12)); veins.addLine(to: CGPoint(x: -3.5, y: 21))
            wing.stroke(veins, with: .color(outline.opacity(0.35)), lineWidth: 1)
        }

        if flash > 0 {
            var hurt = Path()
            hurt.addPath(abdomen)
            hurt.addPath(thorax)
            c.fill(hurt, with: .color(.white.opacity(min(0.75, flash * 0.75))))
        }
    }

    private static func rotate(_ p: CGPoint, around o: CGPoint, by angle: CGFloat) -> CGPoint {
        let dx = p.x - o.x
        let dy = p.y - o.y
        let cosA = cos(angle)
        let sinA = sin(angle)
        return CGPoint(x: o.x + dx * cosA - dy * sinA, y: o.y + dx * sinA + dy * cosA)
    }
}
