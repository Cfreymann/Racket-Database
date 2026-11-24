import UIKit

/// Calls `onFrame(dt)` once per screen refresh while running.
@MainActor
final class DisplayLink: NSObject {
    private var link: CADisplayLink?
    private var lastTimestamp: CFTimeInterval = 0
    private let onFrame: @MainActor (Double) -> Void

    init(onFrame: @escaping @MainActor (Double) -> Void) {
        self.onFrame = onFrame
        super.init()
    }

    func start() {
        guard link == nil else { return }
        lastTimestamp = 0
        let newLink = CADisplayLink(target: self, selector: #selector(tick(_:)))
        newLink.add(to: .main, forMode: .common)
        link = newLink
    }

    func stop() {
        link?.invalidate()
        link = nil
    }

    @objc private func tick(_ sender: CADisplayLink) {
        if lastTimestamp == 0 {
            lastTimestamp = sender.timestamp
            return
        }
        // Clamp so a hitch (or returning from background) doesn't teleport bugs.
        let dt = min(sender.timestamp - lastTimestamp, 1.0 / 20.0)
        lastTimestamp = sender.timestamp
        onFrame(dt)
    }
}
