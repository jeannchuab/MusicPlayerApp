import Foundation

/// Describes the app's current ability to reach the internet.
@MainActor
protocol NetworkConnectionMonitoring {

    // MARK: - Properties

    /// Indicates whether the device currently has a satisfied network path.
    var isConnected: Bool { get }
}
