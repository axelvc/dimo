//
//  MenuBarViewModel.swift
//  dimo
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import Foundation
import Observation

@MainActor
@Observable
final class MenuBarViewModel {
    private let monitorController: any MonitorControlling
    private let settingsStore: any SettingsStoring

    var monitors: [MonitorInfo] {
        monitorController.monitors
    }

    var hasMonitors: Bool {
        !monitors.isEmpty
    }

    var showPresetBar: Bool {
        settingsStore.showPresetBar
    }

    init(
        monitorController: any MonitorControlling,
        settingsStore: any SettingsStoring
    ) {
        self.monitorController = monitorController
        self.settingsStore = settingsStore
    }

    func refreshMonitors() {
        monitorController.collectMonitors()
    }

    func setBrightness(_ brightness: UInt16, for monitor: MonitorInfo) {
        monitorController.setBrightness(brightness, for: monitor)
    }
}
