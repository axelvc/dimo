//
//  ContentView.swift
//  dimo
//
//  External monitor brightness control UI
//

import SwiftUI

struct ContentView: View {
    @StateObject private var monitorManager = MonitorManager()

    var body: some View {
        if monitorManager.monitors.isEmpty {
            emptyStateView
        } else {
            displayListView
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "display.trianglebadge.exclamationmark")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("No External Displays Found")
                .font(.headline)

            Button("Refresh") {
                monitorManager.collectMonitors()
            }
            .padding(.top, 8)
        }
        .padding()
    }

    private var displayListView: some View {
        VStack(spacing: 16) {
            ForEach(monitorManager.monitors, id: \.self.id) { display in
                DisplayControlCard(
                    display: display,
                    onBrightnessChange: { brightness in
                        monitorManager.setBrightness(brightness, for: display)
                    }
                )
            }
        }
    }
}

// MARK: - Display Control Card

struct DisplayControlCard: View {
    let display: MonitorInfo
    let onBrightnessChange: (Double) -> Void

    @State private var sliderValue: Double = 50
    @State private var isDragging = false

    let presets = [0, 25, 50, 75, 100]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Display name
            HStack {
                Image(systemName: "display")
                    .foregroundStyle(.blue)
                Text(display.name)
                    .font(.headline)
                Spacer()
                Text("\(Int(sliderValue))%")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            // Brightness slider
            HStack {
                Button("Sub", systemImage: "sun.min.fill") {
                    sliderValue -= 1
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)

                Slider(
                    value: $sliderValue,
                    in: 0...100,
                ) { editing in
                    isDragging = editing
                    if !editing {
                        onBrightnessChange(sliderValue)
                    }
                }

                Button("Add", systemImage: "sun.max.fill") {
                    sliderValue += 1
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            }

            // Quick preset buttons
            HStack(spacing: 8) {
                ForEach(presets, id: \.self) { preset in
                    Button("\(preset)%") {
                        withAnimation {
                            sliderValue = Double(preset)
                        }
                        onBrightnessChange(Double(preset))
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
        }
        .padding()
        .onAppear {
            sliderValue = Double(display.brightness)
        }
        .onChange(of: display.brightness) { _, newValue in
            if !isDragging {
                sliderValue = Double(newValue)
            }
        }
    }
}

#Preview {
    ContentView()
}
