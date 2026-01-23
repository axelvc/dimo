//
//  dimoApp.swift
//  dimo
//
//  Created by Axel on 18/01/26.
//

import SwiftUI

@main
struct dimoApp: App {
    var body: some Scene {
        MenuBarExtra("Dimo", systemImage: "display") {
            MenuBarView()
        }
        .menuBarExtraStyle(.window)

        Window("Settings", id: "settings") {
            SettingsView()
        }
    }
}
