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
        VStack(spacing: 0) {
            // Content
            Group {
                if monitorManager.isLoading {
                    ProgressView("Detecting displays...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if monitorManager.monitors.isEmpty {
                    emptyStateView
                } else {
                    displayListView
                }
            }
            .padding()
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "display.trianglebadge.exclamationmark")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)

            Text("No External Displays Found")
                .font(.headline)

            Text("Connect an external monitor to control its brightness.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button("Refresh") {
                monitorManager.collectMonitors()
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var displayListView: some View {
        ScrollView {
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
            HStack(spacing: 12) {
                Image(systemName: "sun.min")
                    .foregroundStyle(.secondary)

                Slider(
                    value: $sliderValue,
                    in: 0...100,
                    step: 1
                ) { editing in
                    isDragging = editing
                    if !editing {
                        // Apply brightness when user stops dragging
                        onBrightnessChange(sliderValue)
                    }
                }

                Image(systemName: "sun.max")
                    .foregroundStyle(.secondary)
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
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
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
