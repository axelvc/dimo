//
//  DisplayControlCard.swift
//  dimo
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import SwiftUI

struct DisplayControlCard: View {
    let display: MonitorInfo
    let showPresetBar: Bool
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
                    .contentTransition(.numericText())
            }
            
            // Brightness slider
            HStack {
                Button("Sub", systemImage: "sun.min.fill") {
                    sliderValue = max(0, sliderValue - 1)
                    onBrightnessChange(sliderValue)
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
                    sliderValue = min(100, sliderValue + 1)
                    onBrightnessChange(sliderValue)
                }
                .labelStyle(.iconOnly)
                .buttonStyle(.borderless)
            }
            
            if showPresetBar {
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
