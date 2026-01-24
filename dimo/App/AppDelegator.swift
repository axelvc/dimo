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

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Initialize services by accessing them
        _ = monitorController
        _ = settingsStore
        _ = brightnessScheduler
    }
}
