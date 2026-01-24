//
//  BrightnessScheduleEntryr.swift
//  dimo
//
//  Created by Axel on 23/01/26.
//

import Foundation

struct BrightnessSchedule: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var time: DateComponents
    var percent: UInt16
    var isEnabled: Bool = true
}

@Observable
final class BrightnessScheduler {
    static let shared = BrightnessScheduler()

    private let store = SettingsStore.shared
    private(set) var schedules: [BrightnessSchedule] = []
    private var timers: [UUID: Timer] = [:]

    init() {
        loadSchedules()
    }

    func removeSchedule(id: UUID) {
        timers[id]?.invalidate()
        timers.removeValue(forKey: id)
        schedules.removeAll { $0.id == id }
        store.saveSchedules(schedules)
    }

    func saveSchedule(_ schedule: BrightnessSchedule) {
        if let index = schedules.firstIndex(where: { $0.id == schedule.id }) {
            schedules[index] = schedule
        } else {
            schedules.append(schedule)
        }

        timers[schedule.id]?.invalidate()
        timers.removeValue(forKey: schedule.id)

        if schedule.isEnabled {
            scheduleTimer(for: schedule)
        }

        store.saveSchedules(schedules)
    }

    private func loadSchedules() {
        schedules = store.schedules
        rescheduleAll()
    }

    private func rescheduleAll() {
        timers.values.forEach { $0.invalidate() }
        timers.removeAll()

        for schedule in schedules where schedule.isEnabled {
            scheduleTimer(for: schedule)
        }
    }

    private func scheduleTimer(for schedule: BrightnessSchedule) {
        let timeInterval = calculateTimeInterval(for: schedule)

        let timer = Timer.scheduledTimer(withTimeInterval: timeInterval, repeats: false) {
            [weak self] _ in
            self?.executeBrightnessChange(schedule)
            self?.scheduleTimer(for: schedule)
        }

        timers[schedule.id] = timer
    }

    private func calculateTimeInterval(for schedule: BrightnessSchedule) -> TimeInterval {
        let now = Date()
        let calendar = Calendar.current

        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.hour = schedule.time.hour
        components.minute = schedule.time.minute
        components.second = 0

        guard var scheduledTime = calendar.date(from: components) else { return 0 }

        if scheduledTime <= now {
            scheduledTime = calendar.date(byAdding: .day, value: 1, to: scheduledTime)!
        }

        return scheduledTime.timeIntervalSince(now)
    }

    private func executeBrightnessChange(_ schedule: BrightnessSchedule) {
        MonitorController.shared.setBrightness(schedule.percent)
    }
}
