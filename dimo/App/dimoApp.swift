//
//  dimoApp.swift
//  dimo
//
//  Created by Axel on 22/01/26.
//

import SwiftUI

@main
struct dimoApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: AppDelegator

    var body: some Scene {
        MenuBarExtra("Dimo", systemImage: "display") {
            MenuBarView()
                .environment(\.monitorController, appDelegate.monitorController)
                .environment(\.settingsStore, appDelegate.settingsStore)
        }
        .menuBarExtraStyle(.window)

        Settings {
            SettingsView()
                .environment(\.settingsStore, appDelegate.settingsStore)
                .environment(\.brightnessScheduler, appDelegate.brightnessScheduler)
        }
    }
}
