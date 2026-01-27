import AppKit
import Cocoa
import SwiftUI

@MainActor
protocol KeyboardShortcutManaging: AnyObject {
    func startMonitoring(promptForPermission: Bool)
    func stopMonitoring()
}

@MainActor
class KeyboardShortcutManager: KeyboardShortcutManaging {
    private let settingsStore: any SettingsStoring
    private let monitorController: any MonitorControlling
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    private static let pendingBrightnessFeedbackIntervalMS: UInt64 = 50
    private var pendingBrightnessFeedbackTask: Task<Void, Never>?

    private var lastBrightnessTarget: UInt16?
    private var lastAppliedPendingBrightness: UInt16?

    private enum BrightnessKey {
        case decrease
        case increase

        static func from(_ event: CGEvent) -> BrightnessKey? {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

            switch keyCode {
            case 145:
                return .decrease
            case 144:
                return .increase
            default:
                return nil
            }
        }
    }

    private var activeBrightnessKey: BrightnessKey?
    private var brightnessBeforeKeyHold: UInt16?
    private var pendingBrightness: UInt16?

    var onBrightnessChanged: ((UInt16) -> Void)?

    init(
        settingsStore: any SettingsStoring,
        monitorController: any MonitorControlling
    ) {
        self.settingsStore = settingsStore
        self.monitorController = monitorController
    }

    func startMonitoring(promptForPermission: Bool = false) {
        stopMonitoring()

        guard checkAccessibilityPermissions(promptForPermission: promptForPermission) else {
            print("⚠️ Accessibility permissions not granted. Keyboard shortcuts will not work.")
            return
        }

        // Create event tap
        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.keyUp.rawValue)

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
                        manager.handleCGEvent(type: type, event: event)
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
        stopPendingBrightnessFeedback()

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

    private func checkAccessibilityPermissions(promptForPermission: Bool) -> Bool {
        if promptForPermission {
            let options: NSDictionary = [
                kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
            ]

            return AXIsProcessTrustedWithOptions(options)
        }

        return AXIsProcessTrusted()
    }

    private func handleCGEvent(type: CGEventType, event: CGEvent) {
        switch type {
        case .keyDown:
            handleKeyDown(event)
        case .keyUp:
            handleKeyUp(event)
        default:
            break
        }
    }

    private func currentBrightnessValue() -> UInt16 {
        pendingBrightness ?? lastBrightnessTarget ?? (monitorController.monitors.first?.brightness ?? 50)
    }

    private func handleKeyDown(_ event: CGEvent) {
        guard settingsStore.keyboardShortcutsEnabled else {
            return
        }

        guard event.flags.contains(.maskSecondaryFn) else {
            return
        }

        guard let key = BrightnessKey.from(event) else {
            return
        }

        if activeBrightnessKey != key {
            activeBrightnessKey = key
            let currentBrightness = currentBrightnessValue()
            brightnessBeforeKeyHold = currentBrightness
            pendingBrightness = currentBrightness
            lastBrightnessTarget = currentBrightness
        }

        startPendingBrightnessFeedback()

        guard let newBrightness = stepPendingBrightness(for: key) else {
            return
        }

        lastBrightnessTarget = newBrightness
        onBrightnessChanged?(newBrightness)
    }

    private func handleKeyUp(_ event: CGEvent) {
        guard let key = BrightnessKey.from(event) else {
            return
        }

        guard activeBrightnessKey == key else {
            return
        }

        defer { resetPendingBrightness() }

        guard settingsStore.keyboardShortcutsEnabled else {
            return
        }

        guard
            let initialBrightness = brightnessBeforeKeyHold,
            let finalBrightness = pendingBrightness
        else {
            return
        }

        guard finalBrightness != initialBrightness else {
            return
        }

        lastBrightnessTarget = finalBrightness
        applyPendingBrightnessIfNeeded()
    }

    private func applyPendingBrightnessIfNeeded() {
        guard let pending = pendingBrightness, pending != lastAppliedPendingBrightness else {
            return
        }

        monitorController.setBrightness(pending)
        onBrightnessChanged?(pending)
        lastAppliedPendingBrightness = pending
    }

    private func startPendingBrightnessFeedback() {
        guard pendingBrightnessFeedbackTask == nil else {
            return
        }

        pendingBrightnessFeedbackTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                guard self.activeBrightnessKey != nil else {
                    break
                }

                self.applyPendingBrightnessIfNeeded()

                do {
                    try await Task.sleep(for: .milliseconds(Self.pendingBrightnessFeedbackIntervalMS))
                } catch {
                    break
                }
            }

            self.pendingBrightnessFeedbackTask = nil
        }
    }

    private func stopPendingBrightnessFeedback() {
        pendingBrightnessFeedbackTask?.cancel()
        pendingBrightnessFeedbackTask = nil
        lastAppliedPendingBrightness = nil
    }

    private func stepPendingBrightness(for key: BrightnessKey) -> UInt16? {
        let stepsize = settingsStore.brightnessStepSize
        let delta =
            switch key {
            case .decrease: -stepsize
            case .increase: stepsize
            }

        let currentBrightness = currentBrightnessValue()
        let clampValue = max(0, min(100, Int(currentBrightness) + delta))
        let newBrightness = UInt16(clampValue)

        guard newBrightness != currentBrightness else {
            return nil
        }

        pendingBrightness = newBrightness
        return newBrightness
    }

    private func resetPendingBrightness() {
        stopPendingBrightnessFeedback()
        activeBrightnessKey = nil
        brightnessBeforeKeyHold = nil
        pendingBrightness = nil
    }
}
