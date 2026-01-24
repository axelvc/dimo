//
//  MonitorInfo.swift
//  dimo
//
//  Created by OpenCode Refactoring on 24/01/26.
//

import Foundation

struct MonitorInfo: Identifiable, Equatable {
    let id: String
    let name: String
    var brightness: UInt16
}
