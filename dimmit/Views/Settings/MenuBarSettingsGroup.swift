//
//  MenuBarSettingsGroup.swift
//  Dimmit
//
//  Created by Axel on 30/01/26.
//

import SwiftUI

struct MenuBarSettingsGroup: View {
    @Bindable var viewModel: SettingsViewModel

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Menu Bar")
                .font(.title3)
                .fontWeight(.semibold)

            settingsCard {
                SettingsToggleRow(
                    title: "Show menu bar icon",
                    isOn: showMenuBarIconBinding
                )
                Divider()
                SettingsToggleRow(
                    title: "Show preset bar",
                    isOn: showPresetBarBinding
                )
            }
        }
    }

    private var showPresetBarBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showPresetBar },
            set: { viewModel.setShowPresetBar($0) }
        )
    }

    private var showMenuBarIconBinding: Binding<Bool> {
        Binding(
            get: { viewModel.showMenuBarIcon },
            set: { viewModel.setShowMenuBarIcon($0) }
        )
    }
}
