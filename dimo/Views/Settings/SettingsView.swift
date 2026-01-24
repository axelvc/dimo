//
//  SettingsView.swift
//  dimo
//
//  Created by Axel on 22/01/26.
//

import SwiftUI

struct SettingsView: View {
    @Environment(\.settingsStore) private var settingsStore
    @Environment(\.brightnessScheduler) private var brightnessScheduler

    var body: some View {
        SettingsContentView(
            settingsStore: settingsStore,
            brightnessScheduler: brightnessScheduler
        )
    }
}

// MARK: - Content View

private struct SettingsContentView: View {
    let settingsStore: any SettingsStoring
    let brightnessScheduler: any BrightnessScheduling

    @State private var viewModel: SettingsViewModel

    init(
        settingsStore: any SettingsStoring,
        brightnessScheduler: any BrightnessScheduling
    ) {
        self.settingsStore = settingsStore
        self.brightnessScheduler = brightnessScheduler
        self._viewModel = State(
            initialValue: SettingsViewModel(
                settingsStore: settingsStore,
                scheduler: brightnessScheduler
            ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                GeneralSettingsGroup(viewModel: viewModel)
                SchedulesSettingsGroup(viewModel: viewModel)
            }
            .padding()
        }
        .frame(minWidth: 520, minHeight: 520)
    }
}

// MARK: - Preview

#Preview {
    SettingsView()
        .previewEnvironment()
}
