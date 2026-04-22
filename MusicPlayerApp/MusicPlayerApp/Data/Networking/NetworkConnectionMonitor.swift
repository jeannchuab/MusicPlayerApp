import Foundation
import Network

/// Monitors internet reachability for playback decisions that depend on remote previews.
@MainActor
final class NetworkConnectionMonitor: NetworkConnectionMonitoring {

    // MARK: - Properties

    /// Shared monitor used across the app to avoid redundant path observers.
    static let shared = NetworkConnectionMonitor()

    /// The underlying system path monitor.
    private let pathMonitor = NWPathMonitor()

    /// The dispatch queue used by the system monitor callbacks.
    private let monitorQueue = DispatchQueue(label: "com.jeannchuab.MusicPlayerApp.NetworkConnectionMonitor")

    /// Indicates whether the device currently has a satisfied network path.
    private(set) var isConnected = true

    // MARK: - Initialization

    /// Creates and starts a new network connection monitor.
    private init() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            Task { @MainActor [weak self] in
                self?.isConnected = path.status == .satisfied
            }
        }

        pathMonitor.start(queue: monitorQueue)
    }
}
