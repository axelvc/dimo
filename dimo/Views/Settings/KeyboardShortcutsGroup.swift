import SwiftUI

struct KeyboardShortcutsGroup: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Keyboard Shortcuts")
                .font(.title3)
                .fontWeight(.semibold)

            settingsCard {
                VStack(alignment: .leading, spacing: 0) {
                    SettingsToggleRow(
                        title: "Enable keyboard shortcuts",
                        isOn: keyboardShortcutsEnabledBinding
                    )

                    Divider()

                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Brightness step size")
                                .font(.body)
                            Text("Amount to change brightness per key press")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }

                        Spacer()

                        Picker("Brightness step size", selection: brightnessStepSizeBinding) {
                            ForEach(1...20, id: \.self) { step in
                                Text("\(step) points")
                                    .font(.system(.body, design: .monospaced))
                            }
                        }
                        .labelsHidden()
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 10)
                }
            }
        }
    }

    private var keyboardShortcutsEnabledBinding: Binding<Bool> {
        Binding(
            get: { viewModel.keyboardShortcutsEnabled },
            set: { viewModel.setKeyboardShortcutsEnabled($0) }
        )
    }

    private var brightnessStepSizeBinding: Binding<Int> {
        Binding(
            get: { viewModel.brightnessStepSize },
            set: { viewModel.setBrightnessStepSize($0) }
        )
    }
}
