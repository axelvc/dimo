import Combine
import Foundation

struct Display {
    let id: String
    let name: String
    let brightness: Double = 0
}

@MainActor
class MonitorManager: ObservableObject {
    @Published var displays: [Display] = []
    @Published var isLoading = false

    init() {}

    func collectDisplays() {
    }

    func setBrightness(_ brightness: Double, for display: Display) {
    }
}
