//
//  SettingsViewModel.swift
//  dimmit
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class SettingsViewModel {
    private let settingsStore: any SettingsStoring
    private let scheduler: any BrightnessScheduling

    var openOnStartup: Bool {
        settingsStore.openOnStartup
    }

    var showPresetBar: Bool {
        settingsStore.showPresetBar
    }

    var notifyOnSchedule: Bool {
        settingsStore.notifyOnSchedule
    }

    var keyboardShortcutsEnabled: Bool {
        settingsStore.keyboardShortcutsEnabled
    }

    var brightnessStepSize: Int {
        settingsStore.brightnessStepSize
    }

    var schedules: [BrightnessSchedule] {
        scheduler.schedules
    }

    init(
        settingsStore: any SettingsStoring,
        scheduler: any BrightnessScheduling
    ) {
        self.settingsStore = settingsStore
        self.scheduler = scheduler
    }

    func setOpenOnStartup(_ isEnabled: Bool) {
        settingsStore.setOpenOnStartup(isEnabled)
    }

    func setShowPresetBar(_ isEnabled: Bool) {
        settingsStore.setShowPresetBar(isEnabled)
    }

    func setNotifyOnSchedule(_ isEnabled: Bool) {
        if isEnabled {
            ScheduleBrightnessNotification.requestAuthorizationIfNeeded()
        }
        settingsStore.setNotifyOnSchedule(isEnabled)
    }

    func setKeyboardShortcutsEnabled(_ isEnabled: Bool) {
        settingsStore.setKeyboardShortcutsEnabled(isEnabled)
    }

    func setBrightnessStepSize(_ stepSize: Int) {
        settingsStore.setBrightnessStepSize(stepSize)
    }

    func saveSchedule(_ schedule: BrightnessSchedule) {
        scheduler.saveSchedule(schedule)
    }

    func removeSchedule(id: UUID) {
        scheduler.removeSchedule(id: id)
    }

    func toggleSchedule(_ schedule: BrightnessSchedule, isEnabled: Bool) {
        var updated = schedule
        updated.isEnabled = isEnabled
        scheduler.saveSchedule(updated)
    }
}
