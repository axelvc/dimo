//
//  BrightnessScheduleEditor.swift
//  dimo
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import SwiftUI

struct BrightnessScheduleEditor: View {
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
