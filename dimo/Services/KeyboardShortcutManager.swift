import AppKit
import Cocoa
import SwiftUI

@MainActor
class KeyboardShortcutManager {
    private let settingsStore: any SettingsStoring
    private let monitorController: any MonitorControlling
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    var onBrightnessChanged: ((UInt16) -> Void)?

    init(
        settingsStore: any SettingsStoring,
        monitorController: any MonitorControlling
    ) {
        self.settingsStore = settingsStore
        self.monitorController = monitorController
        observeKeyboardShortcutsSetting()
    }

    private func observeKeyboardShortcutsSetting() {
        Task { @MainActor in
            var wasEnabled = settingsStore.keyboardShortcutsEnabled

            while !Task.isCancelled {
                withObservationTracking {
                    _ = settingsStore.keyboardShortcutsEnabled
                } onChange: {
                    Task { @MainActor in
                        let isEnabled = self.settingsStore.keyboardShortcutsEnabled

                        if isEnabled != wasEnabled {
                            if isEnabled {
                                self.startMonitoring()
                            } else {
                                self.stopMonitoring()
                            }
                            wasEnabled = isEnabled
                        }
                    }
                }

                // Yield to avoid blocking
                await Task.yield()
            }
        }
    }

    func startMonitoring() {
        stopMonitoring()

        guard checkAccessibilityPermissions() else {
            print("⚠️ Accessibility permissions not granted. Keyboard shortcuts will not work.")
            return
        }

        // Create event tap
        let eventMask = (1 << CGEventType.keyDown.rawValue)

        guard
            let eventTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .defaultTap,
                eventsOfInterest: CGEventMask(eventMask),
                callback: { (proxy, type, event, refcon) -> Unmanaged<CGEvent>? in
                    // Get the KeyboardShortcutManager instance
                    let manager = Unmanaged<KeyboardShortcutManager>.fromOpaque(refcon!)
                        .takeUnretainedValue()

                    // Handle the event
                    Task { @MainActor in
                        manager.handleCGEvent(event)
                    }

                    // Pass through the event
                    return Unmanaged.passRetained(event)
                },
                userInfo: Unmanaged.passUnretained(self).toOpaque()
            )
        else {
            print("❌ Failed to create event tap")
            return
        }

        self.eventTap = eventTap

        // Create a run loop source and add it to the current run loop
        runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)

        // Enable the event tap
        CGEvent.tapEnable(tap: eventTap, enable: true)

        print("✓ Keyboard shortcut monitoring started (CGEvent)")
    }

    func stopMonitoring() {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)

            if let runLoopSource = runLoopSource {
                CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
                self.runLoopSource = nil
            }

            self.eventTap = nil
            print("✓ Keyboard shortcut monitoring stopped")
        }
    }

    private func checkAccessibilityPermissions() -> Bool {
        let options: NSDictionary = [
            kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
        ]

        let accessEnabled = AXIsProcessTrustedWithOptions(options)

        return accessEnabled
    }

    private func handleCGEvent(_ event: CGEvent) {
        guard settingsStore.keyboardShortcutsEnabled else {
            return
        }

        let hasFn = event.flags.contains(.maskSecondaryFn)

        if hasFn {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)
            let decreaseKey = Int64(145)
            let increaseKey = Int64(144)

            if keyCode == decreaseKey {
                decreaseBrightness()
            } else if keyCode == increaseKey {
                increaseBrightness()
            }
        }
    }

    private func decreaseBrightness() {
        adjustBrightness(delta: -settingsStore.brightnessStepSize)
    }

    private func increaseBrightness() {
        adjustBrightness(delta: settingsStore.brightnessStepSize)
    }

    private func adjustBrightness(delta: Int) {
        let currentBrightness = monitorController.monitors.first?.brightness ?? 50

        let clampValue = max(0, min(100, Int(currentBrightness) + delta))
        let newBrightness = UInt16(clampValue)

        guard newBrightness != currentBrightness else {
            return
        }

        monitorController.setBrightness(newBrightness)
        onBrightnessChanged?(newBrightness)
    }
}
