//
//  PreviewHelpers.swift
//  dimo
//
//  Created by OpenCode Refactoring on 24/01/26.
//

#if DEBUG
    import SwiftUI

    // MARK: - Mock Services for Previews

    @MainActor
    class MockMonitorController: MonitorControlling {
        var monitors: [MonitorInfo] = [
            MonitorInfo(id: "1", name: "LG UltraWide", brightness: 75),
            MonitorInfo(id: "2", name: "Dell Monitor", brightness: 50),
        ]

        func collectMonitors() {}

        func setBrightness(_ brightness: UInt16, for monitor: MonitorInfo) {
            monitor.brightness = brightness
        }

        func setBrightness(_ brightness: UInt16) {
            for monitor in monitors {
                monitor.brightness = brightness
            }
        }
    }

    class MockSettingsStore: SettingsStoring {
        var schedules: [BrightnessSchedule] = []
        var openOnStartup = true
        var showPresetBar = true
        var notifyOnSchedule = false
        var keyboardShortcutsEnabled = true
        var brightnessStepSize = 5

        func saveSchedules(_ schedules: [BrightnessSchedule]) {
            self.schedules = schedules
        }

        func setOpenOnStartup(_ isEnabled: Bool) {
            openOnStartup = isEnabled
        }

        func setShowPresetBar(_ isEnabled: Bool) {
            showPresetBar = isEnabled
        }

        func setNotifyOnSchedule(_ isEnabled: Bool) {
            notifyOnSchedule = isEnabled
        }

        func setKeyboardShortcutsEnabled(_ isEnabled: Bool) {
            keyboardShortcutsEnabled = isEnabled
        }

        func setBrightnessStepSize(_ stepSize: Int) {
            brightnessStepSize = stepSize
        }
    }

    class MockBrightnessScheduler: BrightnessScheduling {
        var schedules: [BrightnessSchedule] = [
            BrightnessSchedule(
                time: DateComponents(hour: 8, minute: 0),
                percent: 75,
                isEnabled: true
            ),
            BrightnessSchedule(
                time: DateComponents(hour: 20, minute: 0),
                percent: 30,
                isEnabled: false
            ),
        ]

        func removeSchedule(id: UUID) {
            schedules.removeAll { $0.id == id }
        }

        func saveSchedule(_ schedule: BrightnessSchedule) {
            if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
                schedules[index] = schedule
            } else {
                schedules.append(schedule)
            }
        }
    }

    // MARK: - Preview Extension

    extension View {
        @MainActor
        func previewEnvironment() -> some View {
            self
                .environment(\.monitorController, MockMonitorController())
                .environment(\.settingsStore, MockSettingsStore())
                .environment(\.brightnessScheduler, MockBrightnessScheduler())
        }
    }
#endif
