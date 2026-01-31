import Cocoa

@MainActor
protocol KeyboardShortcutManaging: AnyObject {
    var isMonitoring: Bool { get }
    func startMonitoring(promptForPermission: Bool)
    func stopMonitoring()
}

@MainActor
class KeyboardShortcutManager: KeyboardShortcutManaging {
    private let settingsStore: any SettingsStoring
    private let monitorController: any MonitorControlling
    private var eventTap: CFMachPort?
    private var runLoopSource: CFRunLoopSource?

    // CGEventType doesn't expose a .systemDefined case in some SDKs, but the
    // raw value is stable (kCGEventSystemDefined).
    private static let cgEventTypeSystemDefinedRawValue: UInt32 = 14

    private var hasWarnedAboutMissingAccessibilityPermission = false

    private static let accessibilityPermissionRetryInterval: Duration = .seconds(2)
    private var accessibilityPermissionRetryTask: Task<Void, Never>?

    private static let pendingBrightnessFeedbackInterval: Duration = .milliseconds(50)
    private var pendingBrightnessFeedbackTask: Task<Void, Never>?

    private var lastBrightnessTarget: UInt16?
    private var lastAppliedPendingBrightness: UInt16?

    private enum BrightnessKey {
        case decrease
        case increase

        private static let brightnessUpKeyCode: Int64 = 144
        private static let brightnessDownKeyCode: Int64 = 145

        // IOKit/hidsystem/ev_keymap.h
        private static let nxKeytypeBrightnessUp: Int = 2
        private static let nxKeytypeBrightnessDown: Int = 3

        static func from(_ event: CGEvent) -> BrightnessKey? {
            let keyCode = event.getIntegerValueField(.keyboardEventKeycode)

            switch keyCode {
            case brightnessDownKeyCode:
                return .decrease
            case brightnessUpKeyCode:
                return .increase
            default:
                return nil
            }
        }

        static func fromMediaKeyCode(_ code: Int) -> BrightnessKey? {
            switch code {
            case nxKeytypeBrightnessDown:
                return .decrease
            case nxKeytypeBrightnessUp:
                return .increase
            default:
                return nil
            }
        }
    }

    private enum BrightnessKeyEvent {
        case down(BrightnessKey)
        case up(BrightnessKey)
    }

    private enum NXKeyState: Int {
        case down = 0xA  // NX_KEYDOWN
        case up = 0xB  // NX_KEYUP
    }

    private struct BrightnessHold {
        var key: BrightnessKey
        var initial: UInt16
        var pending: UInt16
        var lastApplied: UInt16?
    }

    private var brightnessHold: BrightnessHold?

    var onBrightnessChanged: ((UInt16) -> Void)?

    var isMonitoring: Bool {
        eventTap != nil
    }

    init(
        settingsStore: any SettingsStoring,
        monitorController: any MonitorControlling
    ) {
        self.settingsStore = settingsStore
        self.monitorController = monitorController
    }

    func startMonitoring(promptForPermission: Bool = false) {
        guard settingsStore.keyboardShortcutsEnabled else {
            stopMonitoring()
            return
        }

        guard !isMonitoring else {
            stopAccessibilityPermissionRetryLoop()
            return
        }

        guard checkAccessibilityPermissions(promptForPermission: promptForPermission) else {
            if !hasWarnedAboutMissingAccessibilityPermission {
                print("⚠️ Accessibility permissions not granted. Keyboard shortcuts will not work.")
                hasWarnedAboutMissingAccessibilityPermission = true
            }

            startAccessibilityPermissionRetryLoop()
            return
        }

        hasWarnedAboutMissingAccessibilityPermission = false
        stopAccessibilityPermissionRetryLoop()

        // Create event tap
        let eventMask: CGEventMask =
            (1 << CGEventType.keyDown.rawValue)
            | (1 << CGEventType.keyUp.rawValue)
            | (1 << Self.cgEventTypeSystemDefinedRawValue)

        guard
            let eventTap = CGEvent.tapCreate(
                tap: .cgSessionEventTap,
                place: .headInsertEventTap,
                options: .listenOnly,
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
                    return Unmanaged.passUnretained(event)
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
        let hadResources = (eventTap != nil || runLoopSource != nil)
        stopPendingBrightnessFeedback()
        stopAccessibilityPermissionRetryLoop()

        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
            self.eventTap = nil
        }

        if let runLoopSource = runLoopSource {
            CFRunLoopRemoveSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
            self.runLoopSource = nil
        }

        if hadResources {
            print("✓ Keyboard shortcut monitoring stopped")
        }
    }

    private func startAccessibilityPermissionRetryLoop() {
        guard accessibilityPermissionRetryTask == nil else {
            return
        }

        accessibilityPermissionRetryTask = Task { @MainActor [weak self] in
            guard let self else {
                return
            }

            while !Task.isCancelled {
                guard self.settingsStore.keyboardShortcutsEnabled else {
                    break
                }

                guard !self.isMonitoring else {
                    break
                }

                if self.checkAccessibilityPermissions(promptForPermission: false) {
                    self.startMonitoring(promptForPermission: false)
                }

                do {
                    try await Task.sleep(for: Self.accessibilityPermissionRetryInterval)
                } catch {
                    break
                }
            }

            self.accessibilityPermissionRetryTask = nil
        }
    }

    private func stopAccessibilityPermissionRetryLoop() {
        accessibilityPermissionRetryTask?.cancel()
        accessibilityPermissionRetryTask = nil
    }

    private static var isRunningInXcodePreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private func checkAccessibilityPermissions(promptForPermission: Bool) -> Bool {
        let shouldPromptForPermission = promptForPermission && !Self.isRunningInXcodePreviews

        if shouldPromptForPermission {
            let options: NSDictionary = [
                kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true
            ]

            return AXIsProcessTrustedWithOptions(options)
        }

        return AXIsProcessTrusted()
    }

    private func handleCGEvent(type: CGEventType, event: CGEvent) {
        guard let brightnessKeyEvent = parseBrightnessKeyEvent(type: type, event: event) else {
            return
        }

        switch brightnessKeyEvent {
        case .down(let key):
            guard settingsStore.keyboardShortcutsEnabled else {
                return
            }

            handleBrightnessKeyDown(key)
        case .up(let key):
            let isSystemDefinedEvent = (type.rawValue == Self.cgEventTypeSystemDefinedRawValue)
            if isSystemDefinedEvent, !settingsStore.keyboardShortcutsEnabled {
                return
            }

            handleBrightnessKeyUp(key)
        }
    }

    private func parseBrightnessKeyEvent(type: CGEventType, event: CGEvent) -> BrightnessKeyEvent? {
        if type.rawValue == Self.cgEventTypeSystemDefinedRawValue {
            return parseSystemDefinedBrightnessKeyEvent(event)
        }

        switch type {
        case .keyDown:
            return parseKeyDownBrightnessKeyEvent(event)
        case .keyUp:
            return parseKeyUpBrightnessKeyEvent(event)
        default:
            return nil
        }
    }

    private func parseSystemDefinedBrightnessKeyEvent(_ event: CGEvent) -> BrightnessKeyEvent? {
        guard let nsEvent = NSEvent(cgEvent: event) else {
            return nil
        }

        guard nsEvent.type == .systemDefined else {
            return nil
        }

        guard nsEvent.subtype.rawValue == NX_SUBTYPE_AUX_CONTROL_BUTTONS else {
            return nil
        }

        guard let parsed = parseSystemDefinedAuxControlData1(nsEvent.data1) else {
            return nil
        }

        guard let key = BrightnessKey.fromMediaKeyCode(parsed.keyCode) else {
            return nil
        }

        switch parsed.keyState {
        case .down:
            return .down(key)
        case .up:
            return .up(key)
        }
    }

    // data1 packs the key code and state:
    // - high 16 bits: NX_KEYTYPE_*
    // - bits 8-15 of low 16 bits: NX_KEYDOWN (0xA) / NX_KEYUP (0xB)
    private func parseSystemDefinedAuxControlData1(_ data1: Int) -> (
        keyCode: Int, keyState: NXKeyState
    )? {
        let raw = UInt32(bitPattern: Int32(data1))
        let keyCode = Int((raw & 0xFFFF_0000) >> 16)
        let keyStateRaw = Int((raw & 0x0000_FF00) >> 8)
        guard let keyState = NXKeyState(rawValue: keyStateRaw) else {
            return nil
        }

        return (keyCode: keyCode, keyState: keyState)
    }

    private func parseKeyDownBrightnessKeyEvent(_ event: CGEvent) -> BrightnessKeyEvent? {
        guard event.flags.contains(.maskSecondaryFn) else {
            return nil
        }

        guard let key = BrightnessKey.from(event) else {
            return nil
        }

        return .down(key)
    }

    private func parseKeyUpBrightnessKeyEvent(_ event: CGEvent) -> BrightnessKeyEvent? {
        guard let key = BrightnessKey.from(event) else {
            return nil
        }

        return .up(key)
    }

    private func currentBrightnessValue() -> UInt16 {
        brightnessHold?.pending ?? lastBrightnessTarget
            ?? (monitorController.monitors.first?.brightness ?? 50)
    }

    private func handleBrightnessKeyDown(_ key: BrightnessKey) {
        if brightnessHold?.key != key {
            let currentBrightness = currentBrightnessValue()
            brightnessHold = BrightnessHold(
                key: key,
                initial: currentBrightness,
                pending: currentBrightness,
                lastApplied: nil
            )
            lastBrightnessTarget = currentBrightness
        }

        startPendingBrightnessFeedback()

        guard let newBrightness = stepPendingBrightness(for: key) else {
            return
        }

        lastBrightnessTarget = newBrightness
        onBrightnessChanged?(newBrightness)
    }

    private func handleBrightnessKeyUp(_ key: BrightnessKey) {
        guard brightnessHold?.key == key else {
            return
        }

        defer { resetPendingBrightness() }

        guard settingsStore.keyboardShortcutsEnabled else {
            return
        }

        guard let hold = brightnessHold else {
            return
        }

        let initialBrightness = hold.initial
        let finalBrightness = hold.pending

        guard finalBrightness != initialBrightness else {
            return
        }

        lastBrightnessTarget = finalBrightness
        applyPendingBrightnessIfNeeded()
    }

    private func applyPendingBrightnessIfNeeded() {
        guard var hold = brightnessHold else {
            return
        }

        let pending = hold.pending
        guard pending != hold.lastApplied else {
            return
        }

        monitorController.setBrightness(pending)
        onBrightnessChanged?(pending)
        hold.lastApplied = pending
        brightnessHold = hold
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
                guard self.brightnessHold != nil else {
                    break
                }

                self.applyPendingBrightnessIfNeeded()

                do {
                    try await Task.sleep(for: Self.pendingBrightnessFeedbackInterval)
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
        if var hold = brightnessHold {
            hold.lastApplied = nil
            brightnessHold = hold
        }
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

        if var hold = brightnessHold {
            hold.pending = newBrightness
            brightnessHold = hold
        }
        return newBrightness
    }

    private func resetPendingBrightness() {
        stopPendingBrightnessFeedback()
        brightnessHold = nil
    }
}
