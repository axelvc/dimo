import SwiftUI

/// HUD view that displays current brightness level
struct BrightnessHUDView: View {
    let brightness: UInt16

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and label
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.blue)
                Text("Global Brightness")
                    .font(.headline)
                Spacer()
                Text("\(Int(brightness))%")
                    .font(.system(.body, design: .monospaced))
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
            }

            // Progress bar (non-interactive)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.tertiary)
                        .frame(height: 6)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.blue)
                        .frame(
                            width: geometry.size.width * CGFloat(brightness) / 100.0,
                            height: 6
                        )
                }
            }
            .frame(height: 6)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.2), radius: 12, x: 0, y: 4)
        .frame(width: 280)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    BrightnessHUDView(brightness: 50)
}
