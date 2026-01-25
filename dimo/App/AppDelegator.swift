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
                self?.hudManager.show(brightness: brightness)
            }
        }
        return manager
    }()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize services by accessing them
        _ = monitorController
        _ = settingsStore
        _ = brightnessScheduler

        // Initialize keyboard shortcuts
        Task { @MainActor in
            _ = hudManager
            keyboardManager.startMonitoring()
        }
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Clean up keyboard monitoring
        Task { @MainActor in
            keyboardManager.stopMonitoring()
            hudManager.cleanup()
        }
    }
}
