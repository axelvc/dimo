import SwiftUI

struct MonitorInfo {
    let id: String
    let name: String
    var brightness: UInt16
}

@MainActor
@Observable
class MonitorManager {
    var monitors: [MonitorInfo] = []

    init() {
        self.collectMonitors()
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

    func setBrightness(_ brightness: Double, for monitor: MonitorInfo) {
        let idCString = monitor.id.cString(using: .utf8)

        idCString?.withUnsafeBytes { ptr in
            if let baseAddress = ptr.baseAddress {
                let id = baseAddress.assumingMemoryBound(to: Int8.self)
                ddc_set_monitor_brightness(id, UInt16(brightness))
            }
        }
    }
}
