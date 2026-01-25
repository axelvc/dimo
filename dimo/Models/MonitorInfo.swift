//
//  MonitorInfo.swift
//  dimo
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import Foundation

@Observable
class MonitorInfo: Identifiable {
    let id: String
    let name: String
    var brightness: UInt16

    init(id: String, name: String, brightness: UInt16) {
        self.id = id
        self.name = name
        self.brightness = brightness
    }
}
