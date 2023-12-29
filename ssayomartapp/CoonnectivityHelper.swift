import Foundation
import Network

class ConnectivityHelper: ObservableObject {
    @Published var isConnected: Bool = true

    private var monitor: NWPathMonitor?

    // Singleton instance
    static let shared = ConnectivityHelper()

    private init() {
        startMonitoring()
    }

    private func startMonitoring() {
        monitor = NWPathMonitor()
        let queue = DispatchQueue(label: "ConnectivityMonitor")
        monitor?.start(queue: queue)
        monitor?.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isConnected = path.status == .satisfied
            }
        }
    }

    deinit {
        stopMonitoring()
    }

    private func stopMonitoring() {
        monitor?.cancel()
    }
}
