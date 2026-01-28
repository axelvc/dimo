//
//  ServiceEnvironmentKeys.swift
//  dimmit
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import SwiftUI

// MARK: - Environment Keys

struct MonitorControllerKey: EnvironmentKey {
    @MainActor
    static let defaultValue: any MonitorControlling = {
        #if DEBUG
            MockMonitorController()
        #else
            fatalError(
                "MonitorController not provided in environment. Inject it from AppDelegator.")
        #endif
    }()
}

struct SettingsStoreKey: EnvironmentKey {
    @MainActor
    static let defaultValue: any SettingsStoring = {
        #if DEBUG
            MockSettingsStore()
        #else
            fatalError("SettingsStore not provided in environment. Inject it from AppDelegator.")
        #endif
    }()
}

struct KeyboardShortcutManagerKey: EnvironmentKey {
    @MainActor
    static let defaultValue: any KeyboardShortcutManaging = {
        #if DEBUG
            KeyboardShortcutManager(
                settingsStore: MockSettingsStore(),
                monitorController: MockMonitorController()
            )
        #else
            fatalError(
                "KeyboardShortcutManager not provided in environment. Inject it from AppDelegator.")
        #endif
    }()
}

struct BrightnessSchedulerKey: EnvironmentKey {
    static let defaultValue: any BrightnessScheduling = {
        #if DEBUG
            MockBrightnessScheduler()
        #else
            fatalError(
                "BrightnessScheduler not provided in environment. Inject it from AppDelegator.")
        #endif
    }()
}

// MARK: - Environment Values Extension

extension EnvironmentValues {
    var monitorController: any MonitorControlling {
        get { self[MonitorControllerKey.self] }
        set { self[MonitorControllerKey.self] = newValue }
    }

    var settingsStore: any SettingsStoring {
        get { self[SettingsStoreKey.self] }
        set { self[SettingsStoreKey.self] = newValue }
    }

    var keyboardShortcutManager: any KeyboardShortcutManaging {
        get { self[KeyboardShortcutManagerKey.self] }
        set { self[KeyboardShortcutManagerKey.self] = newValue }
    }

    var brightnessScheduler: any BrightnessScheduling {
        get { self[BrightnessSchedulerKey.self] }
        set { self[BrightnessSchedulerKey.self] = newValue }
    }
}
