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
        MenuBarExtra("Dimmit", systemImage: "display") {
            MenuBarView()
                .environment(\.monitorController, appDelegate.monitorController)
                .environment(\.settingsStore, appDelegate.settingsStore)
                .environment(\.keyboardShortcutManager, appDelegate.keyboardManager)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(\.settingsStore, appDelegate.settingsStore)
                .environment(\.brightnessScheduler, appDelegate.brightnessScheduler)
                .environment(\.keyboardShortcutManager, appDelegate.keyboardManager)
        }
    }
}
