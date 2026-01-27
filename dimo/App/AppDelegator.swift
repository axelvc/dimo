//
//  AppDelegator.swift
//  dimo
//
//  Created by Axel on 24/01/26.
//

import AppKit

final class AppDelegator: NSObject, NSApplicationDelegate {
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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize services by accessing them
        _ = monitorController
        _ = settingsStore
        _ = brightnessScheduler

        // Initialize keyboard shortcuts
        Task { @MainActor in
            _ = hudManager
            if settingsStore.keyboardShortcutsEnabled {
                keyboardManager.startMonitoring(promptForPermission: true)
            }
            registerAccessibilityObserver()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        if let observer = accessibilityObserver {
            NotificationCenter.default.removeObserver(observer)
            accessibilityObserver = nil
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
