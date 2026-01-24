import Foundation

final class SettingsStore {
    static let shared = SettingsStore()

    private let storageKey = "SettingsStore.v1"

    private struct StoredState: Codable {
        var schedules: [BrightnessSchedule]
    }

    private(set) var schedules: [BrightnessSchedule] = []

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
            let state = try? JSONDecoder().decode(StoredState.self, from: data)
        {
            self.schedules = state.schedules
        }
    }

    func saveSchedules(_ schedules: [BrightnessSchedule]) {
        self.schedules = schedules
        saveState()
    }

    private func saveState() {
        let state = StoredState(
            schedules: schedules
        )
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }
}
