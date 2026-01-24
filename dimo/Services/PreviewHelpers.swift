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

        func collectMonitors() {
            // Mock implementation - already has monitors
        }

        func setBrightness(_ brightness: Double, for monitor: MonitorInfo) {
            // Mock implementation
            if let index = monitors.firstIndex(where: { $0.id == monitor.id }) {
                monitors[index].brightness = UInt16(brightness)
            }
        }

        func setBrightness(_ brightness: UInt16) {
            // Mock implementation - set all monitors
            for i in monitors.indices {
                monitors[i].brightness = brightness
            }
        }
    }

    class MockSettingsStore: SettingsStoring {
        var schedules: [BrightnessSchedule] = []
        var openOnStartup = true
        var showPresetBar = true
        var notifyOnSchedule = false

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
