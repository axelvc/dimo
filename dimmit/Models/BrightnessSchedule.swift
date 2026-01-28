//
//  BrightnessSchedule.swift
//  dimmit
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import Foundation

struct BrightnessSchedule: Identifiable, Codable, Equatable {
    var id: UUID = UUID()
    var time: DateComponents
    var percent: UInt16
    var isEnabled: Bool = true
}
