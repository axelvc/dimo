import SwiftUI

/// HUD view that displays current brightness level
struct BrightnessHUDView: View {
    let brightness: UInt16

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header with icon and label
            HStack {
                Image(systemName: "sun.max.fill")
                    .foregroundStyle(.white)
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
                        .fill(.white)
                        .frame(
                            width: geometry.size.width * CGFloat(brightness) / 100.0,
                            height: 6
                        )
                        .animation(.linear, value: brightness)
                }
            }
            .frame(height: 6)
        }
        .padding()
        .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 24))
        .frame(width: 280)
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    BrightnessHUDView(brightness: 50)
}
