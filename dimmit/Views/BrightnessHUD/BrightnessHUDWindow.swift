import AppKit
import SwiftUI

/// Custom panel for displaying the brightness HUD
class BrightnessHUDWindow: NSPanel {
    init() {
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 96),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )

        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = false
        self.level = .statusBar  // Float above normal windows
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.hidesOnDeactivate = false
        self.becomesKeyOnlyIfNeeded = true
        self.acceptsMouseMovedEvents = true
        self.ignoresMouseEvents = false

        positionWindow()
    }

    override var canBecomeKey: Bool {
        true
    }

    override var canBecomeMain: Bool {
        false
    }

    /// Updates window position (in case screen configuration changes)
    func updatePosition(anchorFrame: NSRect? = nil) {
        if let anchorFrame {
            positionBelowMenuBarIcon(anchorFrame: anchorFrame)
        } else {
            positionWindow()
        }
    }

    private func positionBelowMenuBarIcon(anchorFrame: NSRect) {
        let gap: CGFloat = 8
        let x = anchorFrame.midX - (frame.width / 2)
        let y = anchorFrame.minY - gap - frame.height

        let anchorPoint = NSPoint(x: anchorFrame.midX, y: anchorFrame.midY)
        let screen = NSScreen.screens.first { $0.frame.contains(anchorPoint) } ?? NSScreen.main

        guard let screen else {
            setFrameOrigin(NSPoint(x: x, y: y))
            return
        }

        let visibleFrame = screen.visibleFrame
        let clampedX = min(max(x, visibleFrame.minX), visibleFrame.maxX - frame.width)
        let clampedY = min(max(y, visibleFrame.minY), visibleFrame.maxY - frame.height)
        setFrameOrigin(NSPoint(x: clampedX, y: clampedY))
    }

    /// Positions the window at top-right, below menu bar
    func positionWindow() {
        guard let screen = NSScreen.main else { return }

        let screenFrame = screen.frame
        let menuBarHeight: CGFloat = 24  // Standard macOS menu bar height
        let gap: CGFloat = 8  // Gap between menu bar and HUD
        let rightPadding: CGFloat = 20  // Padding from right edge

        // Calculate position: below menu bar, aligned to right
        let x = screenFrame.maxX - frame.width - rightPadding
        let y = screenFrame.maxY - menuBarHeight - gap - frame.height

        setFrameOrigin(NSPoint(x: x, y: y))
    }
}
