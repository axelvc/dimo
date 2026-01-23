//
//  SettingsView.swift
//  dimo
//
//  Created by Axel on 22/01/26.
//

import SwiftUI

struct SettingsView: View {
    @State private var store = SettingsStore()
    @State private var editorEntry: BrightnessScheduleEntry?

    var body: some View {
        VStack {
            HStack {
                Text("Schedule")
                    .font(.headline)
                Spacer()
                Button("Add Schedule", systemImage: "plus") {
                    let nowComponents = Calendar.current.dateComponents([.hour, .minute], from: Date())
                    store.addSchedule(
                        BrightnessScheduleEntry(
                            time: nowComponents,
                            percent: 50
                        )
                    )
                }
                .labelStyle(.iconOnly)
            }

            if sortedEntries.isEmpty {
                Spacer()
                Text("No schedules yet")
                    .foregroundStyle(.secondary)
            } else {
                VStack {
                    ForEach(sortedEntries) { entry in
                        HStack {
                            BrightnessScheduleEditorView(
                                entry: entry,
                                onDelete: {
                                    store.removeSchedule(id: entry.id)
                                }
                            )
                        }
                    }
                }
            }

            Spacer()
        }
        .frame(minWidth: 350, idealWidth: 350, idealHeight: 700)
        .padding()
    }

    private var sortedEntries: [BrightnessScheduleEntry] {
        store.schedules.sorted {
            getTimeDate(for: $0.time) < getTimeDate(for: $1.time)
        }
    }
}

struct BrightnessScheduleEditorView: View {
    @State var entry: BrightnessScheduleEntry
    let onDelete: () -> Void

    @State private var showSlider = false

    var body: some View {
        HStack {
            Text("At")

            DatePicker(
                "Time",
                selection: timeBinding,
                displayedComponents: .hourAndMinute
            )
            .datePickerStyle(.field)
            .labelsHidden()
            .padding(.bottom, -2)

            Text("set brightness to")

            Button("\(entry.percent)%") {
                showSlider = true
            }
            .buttonStyle(.bordered)
            .popover(isPresented: $showSlider, arrowEdge: .bottom) {
                Slider(value: percentBinding, in: 0...100)
                    .frame(width: 200)
                    .padding()
            }

            Spacer()

            Button("Remove", systemImage: "trash") {
                onDelete()
            }
            .foregroundStyle(.red)
            .labelStyle(.iconOnly)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private var timeBinding: Binding<Date> {
        Binding(
            get: {
                getTimeDate(for: entry.time)
            },
            set: { newDate in
                let components = Calendar.current.dateComponents([.hour, .minute], from: newDate)
                entry.time = components
            }
        )
    }

    private var percentBinding: Binding<Double> {
        Binding(
            get: { Double(entry.percent) },
            set: { entry.percent = Int($0) }
        )
    }

}

// MARK: - utilities

func getTimeDate(for components: DateComponents?) -> Date {
    let calendar = Calendar.current
    var merged = calendar.dateComponents([.year, .month, .day], from: Date())
    merged.hour = components?.hour ?? 0
    merged.minute = components?.minute ?? 0
    merged.second = 0
    return calendar.date(from: merged) ?? Date()
}

#Preview {
    SettingsView()
}
