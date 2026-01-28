//
//  SchedulesSettingsGroup.swift
//  dimmit
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import SwiftUI

struct SchedulesSettingsGroup: View {
    @Bindable var viewModel: SettingsViewModel
    @State private var editingSchedule: BrightnessSchedule?
    @State private var isPresentingNewSchedule = false

    private let timeFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView

            settingsCard {
                SettingsToggleRow(
                    title: "Notify when set time",
                    isOn: notifyBinding
                )

                if viewModel.schedules.isEmpty {
                    Divider()
                    Text("Create a schedule to automate brightness changes.")
                        .foregroundStyle(.secondary)
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                } else {
                    Divider()
                    scheduleListView
                }
            }
        }
        .sheet(item: $editingSchedule) { schedule in
            BrightnessScheduleEditor(schedule: schedule) { updatedSchedule in
                viewModel.saveSchedule(updatedSchedule)
            }
        }
        .sheet(isPresented: $isPresentingNewSchedule) {
            BrightnessScheduleEditor(schedule: nil) { newSchedule in
                viewModel.saveSchedule(newSchedule)
            }
        }
    }

    private var headerView: some View {
        HStack {
            Text("Schedules")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            Button("Add Schedule", systemImage: "plus") {
                isPresentingNewSchedule = true
            }
            .buttonStyle(.borderedProminent)
        }
    }

    private var scheduleListView: some View {
        VStack(spacing: 0) {
            ForEach(Array(viewModel.schedules.enumerated()), id: \.element.id) {
                index, schedule in
                scheduleRow(for: schedule)

                if index < viewModel.schedules.count - 1 {
                    Divider()
                }
            }
        }
    }

    private func scheduleRow(for schedule: BrightnessSchedule) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedTime(schedule))
                    .font(.headline)

                Text("Brightness: \(schedule.percent)%")
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Toggle("Enabled", isOn: binding(for: schedule))
                .toggleStyle(.switch)
                .labelsHidden()
                .controlSize(.small)

            Button("Edit", systemImage: "pencil") {
                editingSchedule = schedule
            }
            .labelStyle(.iconOnly)

            Button("Delete", systemImage: "trash") {
                viewModel.removeSchedule(id: schedule.id)
            }
            .labelStyle(.iconOnly)
            .foregroundStyle(.red)
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }

    private func formattedTime(_ schedule: BrightnessSchedule) -> String {
        let calendar = Calendar.current
        var components = calendar.dateComponents(
            [.year, .month, .day],
            from: Date()
        )
        components.hour = schedule.time.hour
        components.minute = schedule.time.minute
        let date = calendar.date(from: components) ?? Date()
        return timeFormatter.string(from: date)
    }

    private var notifyBinding: Binding<Bool> {
        Binding(
            get: { viewModel.notifyOnSchedule },
            set: { viewModel.setNotifyOnSchedule($0) }
        )
    }

    private func binding(for schedule: BrightnessSchedule) -> Binding<Bool> {
        Binding(
            get: { schedule.isEnabled },
            set: { isEnabled in
                viewModel.toggleSchedule(schedule, isEnabled: isEnabled)
            }
        )
    }
}
