import Foundation
import ServiceManagement

protocol SettingsStoring: Observable {
    var schedules: [BrightnessSchedule] { get }
    var openOnStartup: Bool { get }
    var showPresetBar: Bool { get }
    var notifyOnSchedule: Bool { get }

    func saveSchedules(_ schedules: [BrightnessSchedule])
    func setOpenOnStartup(_ isEnabled: Bool)
    func setShowPresetBar(_ isEnabled: Bool)
    func setNotifyOnSchedule(_ isEnabled: Bool)
}

@Observable
final class SettingsStore: SettingsStoring {
    private let storageKey = "SettingsStore.v1"

    private struct StoredState: Codable {
        var schedules: [BrightnessSchedule]
        var openOnStartup: Bool = false
        var showPresetBar: Bool = true
        var notifyOnSchedule: Bool = false
    }

    private(set) var schedules: [BrightnessSchedule] = []
    var openOnStartup = false
    var showPresetBar = true
    var notifyOnSchedule = false

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
            let state = try? JSONDecoder().decode(StoredState.self, from: data)
        {
            self.schedules = state.schedules
            self.openOnStartup = state.openOnStartup
            self.showPresetBar = state.showPresetBar
            self.notifyOnSchedule = state.notifyOnSchedule
        }

        updateLoginItem(enabled: openOnStartup)
    }

    func saveSchedules(_ schedules: [BrightnessSchedule]) {
        self.schedules = schedules
        saveState()
    }

    func setOpenOnStartup(_ isEnabled: Bool) {
        openOnStartup = isEnabled
        updateLoginItem(enabled: isEnabled)
        saveState()
    }

    func setShowPresetBar(_ isEnabled: Bool) {
        showPresetBar = isEnabled
        saveState()
    }

    func setNotifyOnSchedule(_ isEnabled: Bool) {
        notifyOnSchedule = isEnabled
        saveState()
    }

    private func saveState() {
        let state = StoredState(
            schedules: schedules,
            openOnStartup: openOnStartup,
            showPresetBar: showPresetBar,
            notifyOnSchedule: notifyOnSchedule
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func updateLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            openOnStartup = SMAppService.mainApp.status == .enabled
        }
    }
}
