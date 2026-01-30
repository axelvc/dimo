//
//  MenuBarView.swift
//  dimmit
//
//  Created by Axel on 22/01/26.
//

import SwiftUI
import AppKit

struct MenuBarView: View {
    @Environment(\.monitorController) private var monitorController
    @Environment(\.settingsStore) private var settingsStore
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        MenuBarContentView(
            monitorController: monitorController,
            settingsStore: settingsStore,
            openSettings: openSettings
        )
    }
}

// MARK: - Content View

private struct MenuBarContentView: View {
    let monitorController: any MonitorControlling
    let settingsStore: any SettingsStoring
    let openSettings: OpenSettingsAction

    @State private var viewModel: MenuBarViewModel

    init(
        monitorController: any MonitorControlling,
        settingsStore: any SettingsStoring,
        openSettings: OpenSettingsAction
    ) {
        self.monitorController = monitorController
        self.settingsStore = settingsStore
        self.openSettings = openSettings
        self._viewModel = State(
            initialValue: MenuBarViewModel(
                monitorController: monitorController,
                settingsStore: settingsStore
            ))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.hasMonitors {
                displayListView
            } else {
                emptyStateView
            }

            Divider()

            Button(action: {
                openSettings()
                NSApp.activate()
            }) {
                Text("Settings...")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.accessoryBar)
            .cornerRadius(.infinity)
            .padding(4)
        }
    }

    // MARK: - Subviews

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "display.trianglebadge.exclamationmark")
                .font(.title)
                .foregroundStyle(.secondary)

            Text("No External Displays Found")
                .font(.headline)

            Button("Refresh") {
                viewModel.refreshMonitors()
            }
            .padding(.top, 8)
        }
        .padding()
    }

    private var displayListView: some View {
        VStack(spacing: 16) {
            ForEach(viewModel.monitors, id: \.id) { display in
                DisplayControlCard(
                    display: display,
                    showPresetBar: viewModel.showPresetBar,
                    onBrightnessChange: { brightness in
                        viewModel.setBrightness(brightness, for: display)
                    }
                )
            }
        }
    }
}

// MARK: - Preview

#Preview {
    MenuBarView()
        .frame(width: 350)
}
