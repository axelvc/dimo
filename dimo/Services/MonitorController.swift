import CoreLocation
import SwiftUI

@MainActor
protocol MonitorControlling: Observable {
    var monitors: [MonitorInfo] { get }
    func collectMonitors()
    func setBrightness(_ brightness: UInt16, for monitor: MonitorInfo)
    func setBrightness(_ brightness: UInt16)
}

@MainActor
@Observable
class MonitorController: MonitorControlling {
    var monitors: [MonitorInfo] = []

    init() {
        collectMonitors()
    }

    func collectMonitors() {
        var count: UInt = 0

        guard let monitorsPtr = ddc_get_monitors(&count) else {
            self.monitors = []
            return
        }

        defer {
            ddc_free_monitors(monitorsPtr, count)
        }

        var monitors: [MonitorInfo] = []
        for i in 0..<Int(count) {
            let cMonitor = monitorsPtr.advanced(by: i).pointee

            let id = String(cString: cMonitor.id)
            let name = String(cString: cMonitor.name)

            monitors.append(
                MonitorInfo(
                    id: id,
                    name: name,
                    brightness: cMonitor.brightness
                ))
        }

        self.monitors = monitors
    }

    func setBrightness(_ percent: UInt16, for monitor: MonitorInfo) {
        let idCString = monitor.id.cString(using: .utf8)

        guard percent > 0 && percent <= 100 else {
            return
        }

        idCString?.withUnsafeBytes { ptr in
            if let baseAddress = ptr.baseAddress {
                let id = baseAddress.assumingMemoryBound(to: Int8.self)
                ddc_set_monitor_brightness(percent, id)
            }
        }
    }

    func setBrightness(_ percent: UInt16) {
        ddc_set_brightness(percent)
    }
}
