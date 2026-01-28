//
//  ScheduleBrightnessNotification.swift
//  dimmit
//
//  Created by OpenCode on 27/01/26.
//

import Foundation
import UserNotifications

enum ScheduleBrightnessNotification {
    static func requestAuthorizationIfNeeded() {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            guard settings.authorizationStatus == .notDetermined else {
                return
            }

            center.requestAuthorization(options: [.alert, .sound]) { _, _ in
                // No-op: user can manage permissions in System Settings.
            }
        }
    }

    static func postScheduledBrightnessChanged(percent: UInt16, scheduledTime: DateComponents) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .authorized, .provisional:
                break
            default:
                return
            }

            let content = UNMutableNotificationContent()
            content.title = "Brightness updated"
            content.body = "Set to \(percent)% from schedule."
            content.sound = .default

            let request = UNNotificationRequest(
                identifier: "brightness.schedule.\(UUID().uuidString)",
                content: content,
                trigger: nil
            )

            center.add(request) { _ in
                // Intentionally ignored.
            }
        }
    }
}
