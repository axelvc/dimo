//
//  AppDelegator.swift
//  dimo
//
//  Created by Axel on 24/01/26.
//

import AppKit

final class AppDelegator: NSObject, NSApplicationDelegate {
    private static var isRunningInXcodePreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    // Service instances - created once at app launch
    @MainActor
    private(set) lazy var monitorController: MonitorController = {
        MonitorController()
    }()

    @MainActor
    private(set) lazy var settingsStore: SettingsStore = {
        SettingsStore()
    }()

    private(set) lazy var brightnessScheduler: BrightnessScheduler = {
        BrightnessScheduler(
            settingsStore: settingsStore,
            monitorController: monitorController
        )
    }()

    @MainActor
    private(set) lazy var hudManager: BrightnessHUDManager = {
        BrightnessHUDManager()
    }()

    @MainActor
    private(set) lazy var keyboardManager: KeyboardShortcutManager = {
        let manager = KeyboardShortcutManager(
            settingsStore: settingsStore,
            monitorController: monitorController
        )
        // Connect keyboard manager to HUD manager
        manager.onBrightnessChanged = { [weak self] brightness in
            Task { @MainActor in
                let anchorFrame = self?.menuBarButtonFrame()
                self?.hudManager.show(brightness: brightness, anchorFrame: anchorFrame)
            }
        }
        return manager
    }()

    private var accessibilityObserver: NSObjectProtocol?
    private var windowLifecycleObservers: [NSObjectProtocol] = []

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize services by accessing them
        _ = monitorController
        _ = settingsStore
        _ = brightnessScheduler

        // Initialize keyboard shortcuts
        Task { @MainActor in
            if !Self.isRunningInXcodePreviews {
                installWindowLifecycleObservers()
            }
            updateDockVisibility()

            _ = hudManager
            if settingsStore.keyboardShortcutsEnabled {
                keyboardManager.startMonitoring(promptForPermission: !Self.isRunningInXcodePreviews)
            }

            if !Self.isRunningInXcodePreviews {
                registerAccessibilityObserver()
            }
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let observer = accessibilityObserver {
            NotificationCenter.default.removeObserver(observer)
            accessibilityObserver = nil
        }

        if !windowLifecycleObservers.isEmpty {
            for observer in windowLifecycleObservers {
                NotificationCenter.default.removeObserver(observer)
            }
            windowLifecycleObservers.removeAll()
        }

        // Clean up keyboard monitoring
        Task { @MainActor in
            keyboardManager.stopMonitoring()
            hudManager.cleanup()
        }
    }

    private func registerAccessibilityObserver() {
        guard accessibilityObserver == nil else {
            return
        }

        accessibilityObserver = NotificationCenter.default.addObserver(
            forName: NSApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else {
                return
            }

            Task { @MainActor in
                if self.settingsStore.keyboardShortcutsEnabled {
                    self.keyboardManager.startMonitoring(promptForPermission: false)
                } else {
                    self.keyboardManager.stopMonitoring()
                }
            }
        }
    }

    @MainActor
    private func installWindowLifecycleObservers() {
        guard windowLifecycleObservers.isEmpty else {
            return
        }

        let center = NotificationCenter.default
        let names: [NSNotification.Name] = [
            NSWindow.didBecomeKeyNotification,
            NSWindow.didResignKeyNotification,
            NSWindow.didMiniaturizeNotification,
            NSWindow.didDeminiaturizeNotification,
            NSWindow.willCloseNotification,
        ]

        windowLifecycleObservers = names.map { name in
            center.addObserver(forName: name, object: nil, queue: .main) { [weak self] _ in
                guard let self else {
                    return
                }

                if name == NSWindow.willCloseNotification {
                    DispatchQueue.main.async { [weak self] in
                        guard let self else {
                            return
                        }

                        Task { @MainActor in
                            self.updateDockVisibility()
                        }
                    }
                } else {
                    Task { @MainActor in
                        self.updateDockVisibility()
                    }
                }
            }
        }
    }

    @MainActor
    private func updateDockVisibility() {
        let hasUserFacingWindow = NSApp.windows.contains(where: windowCountsForDock)
        let desiredPolicy: NSApplication.ActivationPolicy = hasUserFacingWindow ? .regular : .accessory
        guard NSApp.activationPolicy() != desiredPolicy else {
            return
        }

        _ = NSApp.setActivationPolicy(desiredPolicy)
    }

    @MainActor
    private func windowCountsForDock(_ window: NSWindow) -> Bool {
        if window.className.contains("NSStatusBarWindow") {
            return false
        }

        if window is BrightnessHUDWindow {
            return false
        }

        if window.level == .statusBar {
            return false
        }

        if window.styleMask.contains(.borderless) && !window.styleMask.contains(.titled) {
            return false
        }

        return window.isVisible || window.isMiniaturized
    }

    @MainActor
    private func menuBarButtonFrame() -> NSRect? {
        guard
            let statusBarWindow = NSApp.windows.first(where: {
                $0.className.contains("NSStatusBarWindow")
            })
        else {
            return nil
        }

        guard let contentView = statusBarWindow.contentView,
            let button = findStatusBarButton(in: contentView),
            let buttonWindow = button.window
        else {
            return nil
        }

        return buttonWindow.convertToScreen(button.frame)
    }

    @MainActor
    private func findStatusBarButton(in view: NSView) -> NSStatusBarButton? {
        if let button = view as? NSStatusBarButton {
            return button
        }

        for subview in view.subviews {
            if let button = findStatusBarButton(in: subview) {
                return button
            }
        }

        return nil
    }
}
