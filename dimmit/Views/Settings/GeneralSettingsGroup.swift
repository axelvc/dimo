//
//  GeneralSettingsGroup.swift
//  dimmit
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
            }
        }
    }

    private var openOnStartupBinding: Binding<Bool> {
        Binding(
            get: { viewModel.openOnStartup },
            set: { viewModel.setOpenOnStartup($0) }
        )
    }
}
