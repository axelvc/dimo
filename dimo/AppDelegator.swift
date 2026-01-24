//
//  AppDelegator.swift
//  dimo
//
//  Created by Axel on 24/01/26.
//

import AppKit

final class AppDelegator: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        _ = MonitorController.shared
        _ = BrightnessScheduler.shared
    }
}
