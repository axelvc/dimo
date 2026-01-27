import AppKit
import SwiftUI

/// Manages the brightness HUD window lifecycle and animations
@MainActor
class BrightnessHUDManager {
    private var hudWindow: BrightnessHUDWindow?
    private var hideTask: Task<Void, Never>?

    func show(brightness: UInt16, anchorFrame: NSRect? = nil) {
        hideTask?.cancel()

        hudWindow = hudWindow ?? BrightnessHUDWindow()
        guard let window = hudWindow else { return }

        let contentView = BrightnessHUDView(brightness: brightness)
        window.contentView = NSHostingView(rootView: contentView)

        // Update position (in case screen config changed)
        window.updatePosition(anchorFrame: anchorFrame)

        // Show window with fade-in animation
        if !window.isVisible {
            window.alphaValue = 0.0
            window.orderFrontRegardless()
        }

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.2
            window.animator().alphaValue = 1.0
        }

        scheduleHide()
    }

    func hide() {
        guard let window = hudWindow, window.isVisible else { return }

        NSAnimationContext.runAnimationGroup(
            { context in
                context.duration = 0.2
                window.animator().alphaValue = 0.0
            },
            completionHandler: {
                window.orderOut(nil)
            }
        )
    }

    private func scheduleHide(after seconds: TimeInterval = 2) {
        hideTask?.cancel()
        hideTask = Task {
            try? await Task.sleep(for: .seconds(seconds))

            // Only hide if task wasn't cancelled
            if !Task.isCancelled {
                self.hide()
            }
        }
    }

    func cleanup() {
        hideTask?.cancel()
        hudWindow?.orderOut(nil)
        hudWindow = nil
    }
}
