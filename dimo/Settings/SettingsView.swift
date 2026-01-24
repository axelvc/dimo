//
//  SettingsView.swift
//  dimo
//
//  Created by Axel on 22/01/26.
//

import SwiftUI

struct SettingsView: View {
    @State private var settingsStore = SettingsStore.shared

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GeneralSettingsGroup(store: settingsStore)
                SchedulesSettingsGroup(store: settingsStore)
            }
            .padding()
        }
        .frame(minWidth: 520, minHeight: 520)
    }
}

private struct GeneralSettingsGroup: View {
    @Bindable var store: SettingsStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("General")
                .font(.title3)
                .fontWeight(.semibold)

            settingsCard {
                SettingsToggleRow(
                    title: "Open on startup",
                    isOn: openOnStartupBinding
                )
                Divider()
                SettingsToggleRow(
                    title: "Show preset bar",
                    isOn: showPresetBarBinding
                )
            }
        }
    }

    private var openOnStartupBinding: Binding<Bool> {
        Binding(
            get: { store.openOnStartup },
            set: { store.setOpenOnStartup($0) }
        )
    }

    private var showPresetBarBinding: Binding<Bool> {
        Binding(
            get: { store.showPresetBar },
            set: { store.setShowPresetBar($0) }
        )
    }
}

private struct SchedulesSettingsGroup: View {
    @Bindable var store: SettingsStore
    @State private var scheduler = BrightnessScheduler.shared
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

                if scheduler.schedules.isEmpty {
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
            BrightnessScheduleEditorView(schedule: schedule) { updatedSchedule in
                scheduler.saveSchedule(updatedSchedule)
            }
        }
        .sheet(isPresented: $isPresentingNewSchedule) {
            BrightnessScheduleEditorView(schedule: nil) { newSchedule in
                scheduler.saveSchedule(newSchedule)
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
            ForEach(Array(scheduler.schedules.enumerated()), id: \.element.id) {
                index, schedule in
                scheduleRow(for: schedule)

                if index < scheduler.schedules.count - 1 {
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
                scheduler.removeSchedule(id: schedule.id)
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
            get: { store.notifyOnSchedule },
            set: { store.setNotifyOnSchedule($0) }
        )
    }

    private func binding(for schedule: BrightnessSchedule) -> Binding<Bool> {
        Binding(
            get: { schedule.isEnabled },
            set: { isEnabled in
                var updated = schedule
                updated.isEnabled = isEnabled
                scheduler.saveSchedule(updated)
            }
        )
    }
}

private struct SettingsToggleRow: View {
    let title: String
    let isOn: Binding<Bool>

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)

            Spacer()

            Toggle("", isOn: isOn)
                .labelsHidden()
        }
        .padding(.horizontal)
        .padding(.vertical, 10)
    }
}

private struct SettingsCard<Content: View>: View {
    let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            content
        }
        .background(
            Color(nsColor: .windowBackgroundColor),
            in: RoundedRectangle(cornerRadius: 16)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color(nsColor: .separatorColor), lineWidth: 0.5)
        )
    }
}

private func settingsCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
    SettingsCard(content: content)
}

private struct BrightnessScheduleEditorView: View {
    @Environment(\.dismiss) private var dismiss

    let schedule: BrightnessSchedule?
    let onSave: (BrightnessSchedule) -> Void

    @State private var time: Date
    @State private var percent: Double
    @State private var isEnabled: Bool

    init(
        schedule: BrightnessSchedule?,
        onSave: @escaping (BrightnessSchedule) -> Void
    ) {
        let calendar = Calendar.current
        var components = calendar.dateComponents(
            [.year, .month, .day, .hour, .minute],
            from: Date()
        )

        if let time = schedule?.time {
            components.hour = time.hour
            components.minute = time.minute
        }

        _time = State(initialValue: calendar.date(from: components) ?? Date())
        _percent = State(initialValue: Double(schedule?.percent ?? 50))
        _isEnabled = State(initialValue: schedule?.isEnabled ?? true)
        self.schedule = schedule
        self.onSave = onSave
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text(schedule == nil ? "New Schedule" : "Edit Schedule")
                .font(.title2)
                .fontWeight(.semibold)
                .padding()

            Form {
                DatePicker(
                    "Time",
                    selection: $time,
                    displayedComponents: .hourAndMinute
                )
                HStack {
                    Text("Brightness")
                    Slider(value: $percent, in: 0...100)
                    Text("\(Int(percent))%")
                }
                Toggle("Enabled", isOn: $isEnabled)
            }
            .formStyle(.grouped)
            .contentMargins(0)

            HStack {
                Spacer()

                Button("Cancel") {
                    dismiss()
                }

                Button("Save") {
                    onSave(buildSchedule())
                    dismiss()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding()
        }
    }

    private func buildSchedule() -> BrightnessSchedule {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.hour, .minute], from: time)

        return BrightnessSchedule(
            id: schedule?.id ?? UUID(),
            time: components,
            percent: UInt16(percent),
            isEnabled: isEnabled
        )
    }
}

#Preview {
    SettingsView()
}
