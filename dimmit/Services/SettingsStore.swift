import Foundation
import ServiceManagement

protocol SettingsStoring: Observable {
    var schedules: [BrightnessSchedule] { get }
    var openOnStartup: Bool { get }
    var showMenuBarIcon: Bool { get }
    var showPresetBar: Bool { get }
    var notifyOnSchedule: Bool { get }
    var keyboardShortcutsEnabled: Bool { get }
    var brightnessStepSize: Int { get }

    func saveSchedules(_ schedules: [BrightnessSchedule])
    func setOpenOnStartup(_ isEnabled: Bool)
    func setShowMenuBarIcon(_ isEnabled: Bool)
    func setShowPresetBar(_ isEnabled: Bool)
    func setNotifyOnSchedule(_ isEnabled: Bool)
    func setKeyboardShortcutsEnabled(_ isEnabled: Bool)
    func setBrightnessStepSize(_ stepSize: Int)
}

@Observable
final class SettingsStore: SettingsStoring {
    private let storageKey = "SettingsStore.v1"

    private struct StoredState: Codable {
        var schedules: [BrightnessSchedule]
        var openOnStartup: Bool = false
        var showMenuBarIcon: Bool = true
        var showPresetBar: Bool = true
        var notifyOnSchedule: Bool = false
        var keyboardShortcutsEnabled: Bool = true
        var brightnessStepSize: Int = 5
    }

    private(set) var schedules: [BrightnessSchedule] = []
    var openOnStartup = false
    var showMenuBarIcon = true
    var showPresetBar = true
    var notifyOnSchedule = false
    var keyboardShortcutsEnabled = true
    var brightnessStepSize = 5

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
            let state = try? JSONDecoder().decode(StoredState.self, from: data)
        {
            self.schedules = state.schedules
            self.openOnStartup = state.openOnStartup
            self.showMenuBarIcon = state.showMenuBarIcon
            self.showPresetBar = state.showPresetBar
            self.notifyOnSchedule = state.notifyOnSchedule
            self.keyboardShortcutsEnabled = state.keyboardShortcutsEnabled
            self.brightnessStepSize = state.brightnessStepSize
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

    func setShowMenuBarIcon(_ isEnabled: Bool) {
        showMenuBarIcon = isEnabled
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

    func setKeyboardShortcutsEnabled(_ isEnabled: Bool) {
        keyboardShortcutsEnabled = isEnabled
        saveState()
    }

    func setBrightnessStepSize(_ stepSize: Int) {
        brightnessStepSize = max(1, min(20, stepSize))
        saveState()
    }

    private func saveState() {
        let state = StoredState(
            schedules: schedules,
            openOnStartup: openOnStartup,
            showMenuBarIcon: showMenuBarIcon,
            showPresetBar: showPresetBar,
            notifyOnSchedule: notifyOnSchedule,
            keyboardShortcutsEnabled: keyboardShortcutsEnabled,
            brightnessStepSize: brightnessStepSize,
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
