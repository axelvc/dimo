//
//  ServiceEnvironmentKeys.swift
//  dimmit
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import SwiftUI

// MARK: - Environment Keys

struct MonitorControllerKey: EnvironmentKey {
    static let defaultValue: MonitorControlling = MockMonitorController()
}

struct SettingsStoreKey: EnvironmentKey {
    static let defaultValue: SettingsStoring = MockSettingsStore()
}

struct KeyboardShortcutManagerKey: EnvironmentKey {
    static let defaultValue: KeyboardShortcutManaging = MockKeyboardShortcutManager()
}

struct BrightnessSchedulerKey: EnvironmentKey {
    static let defaultValue: BrightnessScheduling = MockBrightnessScheduler()
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
