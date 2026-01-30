import SwiftUI

/// HUD view that displays current brightness level
struct BrightnessHUDView: View {
    let brightness: UInt16
    let onBrightnessChange: (UInt16) -> Void
    let onHoverChange: (Bool) -> Void
    let onClose: () -> Void

    @State private var display: MonitorInfo
    @State private var isHovering: Bool = false

    init(
        brightness: UInt16,
        onBrightnessChange: @escaping (UInt16) -> Void,
        onHoverChange: @escaping (Bool) -> Void,
        onClose: @escaping () -> Void
    ) {
        self.brightness = brightness
        self.onBrightnessChange = onBrightnessChange
        self.onHoverChange = onHoverChange
        self.onClose = onClose
        _display = State(
            initialValue: MonitorInfo(
                id: "global",
                name: "Brightnesss",
                brightness: brightness
            )
        )
    }

    var body: some View {
        let card = DisplayControlCard(
            display: display,
            showPresetBar: false,
            onBrightnessChange: { newBrightness in
                display.brightness = newBrightness
                onBrightnessChange(newBrightness)
            }
        )

        Group {
            if #available(macOS 26.0, *) {
                card
                    .glassEffect(.clear, in: RoundedRectangle(cornerRadius: 24))
            } else {
                card
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
            }
        }
        .frame(width: 280)
        .overlay(alignment: .topLeading) {
            if isHovering {
                Button(action: onClose) {
                    let image = Image(systemName: "xmark")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundStyle(.white)
                        .padding(5)

                    if #available(macOS 26.0, *) {
                        image
                            .glassEffect()
                    } else {
                        image
                    }
                }
                .buttonStyle(.plain)
                .padding(8)
                .transition(.opacity.combined(with: .scale(scale: 0.9)))
                .offset(x: -12, y: -12)
            }
        }
        .onHover { hovering in
            withAnimation(.easeOut(duration: 0.12)) {
                isHovering = hovering
            }
            onHoverChange(hovering)
        }
        .onChange(of: brightness) { _, newValue in
            display.brightness = newValue
        }
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    BrightnessHUDView(
        brightness: 50,
        onBrightnessChange: { _ in },
        onHoverChange: { _ in },
        onClose: {}
    )
}
