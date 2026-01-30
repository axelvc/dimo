//
//  AppDelegator.swift
//  dimmit
//
//  Created by Axel on 24/01/26.
//

import AppKit
import UserNotifications

final class AppDelegator: NSObject, NSApplicationDelegate {
    private static var isRunningInXcodePreviews: Bool {
        ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
    }

    private(set) var settingsStore: SettingsStore
    private(set) var monitorController: MonitorController
    private(set) var brightnessScheduler: BrightnessScheduler
    private(set) var keyboardManager: KeyboardShortcutManager

    private(set) var hudManager: BrightnessHUDManager = BrightnessHUDManager()
    private var windowLifecycleObservers: [NSObjectProtocol] = []

    override init() {
        settingsStore = SettingsStore()
        monitorController = MonitorController()
        brightnessScheduler = BrightnessScheduler(
            settingsStore: settingsStore,
            monitorController: monitorController
        )
        keyboardManager = KeyboardShortcutManager(
            settingsStore: settingsStore,
            monitorController: monitorController
        )

        super.init()

        // Connect keyboard manager to HUD manager
        keyboardManager.onBrightnessChanged = { [weak self] brightness in
            Task { @MainActor in
                let anchorFrame = self?.menuBarButtonFrame()
                self?.hudManager.show(
                    brightness: brightness,
                    anchorFrame: anchorFrame,
                    setBrightness: { [weak self] newBrightness in
                        Task { @MainActor in
                            self?.monitorController.setBrightness(newBrightness)
                        }
                    }
                )
            }
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        UNUserNotificationCenter.current().delegate = self

        // Initialize services by accessing them
        _ = monitorController
        _ = settingsStore
        _ = brightnessScheduler

        if settingsStore.notifyOnSchedule && !Self.isRunningInXcodePreviews {
            ScheduleBrightnessNotification.requestAuthorizationIfNeeded()
        }

        // Initialize keyboard shortcuts
        Task { @MainActor in
            if !Self.isRunningInXcodePreviews {
                installWindowLifecycleObservers()
            }
            updateDockVisibility()

            if self.settingsStore.keyboardShortcutsEnabled {
                self.keyboardManager.startMonitoring(promptForPermission: true)
            } else {
                self.keyboardManager.stopMonitoring()
            }
        }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return false
    }

    @MainActor var openSettings: (() -> Void)?

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows: Bool)
        -> Bool
    {
        openSettings?()
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
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

        #if DEBUG
            let desiredPolicy: NSApplication.ActivationPolicy = .regular
        #else
            let desiredPolicy: NSApplication.ActivationPolicy =
                hasUserFacingWindow ? .regular : .accessory
        #endif

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
        guard settingsStore.showMenuBarIcon else {
            return nil
        }

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

extension AppDelegator: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler:
            @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        completionHandler([.banner, .sound])
    }
}
