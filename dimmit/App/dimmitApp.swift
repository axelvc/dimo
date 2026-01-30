//
//  dimmitApp.swift
//  dimmit
//
//  Created by Axel on 22/01/26.
//

import SwiftUI

@main
struct dimmitApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegator

    var body: some Scene {
        Settings {
            SettingsView()
                .environment(\.settingsStore, appDelegate.settingsStore)
                .environment(\.brightnessScheduler, appDelegate.brightnessScheduler)
                .environment(\.keyboardShortcutManager, appDelegate.keyboardManager)
        }
        .defaultLaunchBehavior(.suppressed)

        MenuBarExtra(isInserted: showMenuBarIconBinding) {
            MenuBarView()
                .environment(\.monitorController, appDelegate.monitorController)
                .environment(\.settingsStore, appDelegate.settingsStore)
                .environment(\.keyboardShortcutManager, appDelegate.keyboardManager)
        } label: {
            Label("Dimmit", systemImage: "display").background(
                SettingsWindowRegistrar(appDelegate: appDelegate))
        }
        .menuBarExtraStyle(.window)
    }

    private var showMenuBarIconBinding: Binding<Bool> {
        Binding(
            get: { appDelegate.settingsStore.showMenuBarIcon },
            set: { appDelegate.settingsStore.setShowMenuBarIcon($0) }
        )
    }
}

// Hack to open settings window when dimmit is launched
private struct SettingsWindowRegistrar: View {
    let appDelegate: AppDelegator
    @Environment(\.openSettings) private var openSettings

    var body: some View {
        Color.clear
            .frame(width: 0, height: 0)
            .task { @MainActor in
                appDelegate.openSettings = {
                    openSettings()
                    NSApp.activate()
                }
            }
    }
}
