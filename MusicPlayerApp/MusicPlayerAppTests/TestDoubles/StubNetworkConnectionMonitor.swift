import Foundation
@testable import MusicPlayerApp

/// A configurable connection monitor test double for playback availability checks.
@MainActor
final class StubNetworkConnectionMonitor: NetworkConnectionMonitoring {

    // MARK: - Properties

    /// Indicates whether the stub should report internet connectivity.
    var isConnected: Bool

    // MARK: - Initialization

    /// Creates a stub connection monitor.
    ///
    /// - Parameter isConnected: Indicates whether the stub should report internet connectivity.
    init(isConnected: Bool = true) {
        self.isConnected = isConnected
    }
}
