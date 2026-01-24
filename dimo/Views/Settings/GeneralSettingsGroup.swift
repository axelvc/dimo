//
//  GeneralSettingsGroup.swift
//  dimo
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import SwiftUI

struct GeneralSettingsGroup: View {
    @Bindable var viewModel: SettingsViewModel

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
            get: { viewModel.openOnStartup },
            set: { viewModel.setOpenOnStartup($0) }
        )
    }

    private var showPresetBarBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showPresetBar },
            set: { viewModel.setShowPresetBar($0) }
        )
    }
}
