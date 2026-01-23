import Foundation

struct BrightnessScheduleEntry: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var time: DateComponents?
    var percent: Int
}

@MainActor
@Observable
final class SettingsStore {
    private let storageKey = "ScheduleStore.v1"

    private struct StoredState: Codable {
        var schedules: [BrightnessScheduleEntry]
    }

    var schedules: [BrightnessScheduleEntry] {
        didSet {
            saveState()
            onChange?()
        }
    }

    var onChange: (() -> Void)?

    init() {
        if let data = UserDefaults.standard.data(forKey: storageKey),
            let state = try? JSONDecoder().decode(StoredState.self, from: data)
        {
            self.schedules = state.schedules
        } else {
            self.schedules = []
        }
    }

    func addSchedule(_ entry: BrightnessScheduleEntry) {
        if let index = schedules.firstIndex(where: { $0.id == entry.id }) {
            schedules[index] = entry
        } else {
            schedules.append(entry)
        }
    }

    func removeSchedule(id: UUID) {
        schedules.removeAll { $0.id == id }
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
