import AppKit
import SwiftUI

/// Custom NSWindow for displaying the brightness HUD
class BrightnessHUDWindow: NSWindow {
    init() {
        // Create window with initial size
        // Will be positioned below menu bar at top-right
        super.init(
            contentRect: NSRect(x: 0, y: 0, width: 280, height: 80),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )

        // Window configuration
        self.isOpaque = false
        self.backgroundColor = .clear
        self.hasShadow = true
        self.level = .statusBar  // Float above normal windows
        self.collectionBehavior = [.canJoinAllSpaces, .stationary]
        self.ignoresMouseEvents = true  // Click-through

        // Position at top-right, below menu bar
        positionWindow()
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

        self.setFrameOrigin(NSPoint(x: x, y: y))
    }

    /// Updates window position (in case screen configuration changes)
    func updatePosition() {
        positionWindow()
    }
}
