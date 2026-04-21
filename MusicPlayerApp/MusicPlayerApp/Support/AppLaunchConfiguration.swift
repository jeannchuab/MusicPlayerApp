import Foundation

/// Captures launch-time flags that alter app behavior for tests and local runs.
struct AppLaunchConfiguration {

    // MARK: - Properties

    /// Indicates whether the splash screen should be skipped.
    let skipsSplash: Bool

    /// Indicates whether deterministic UI test data should be used.
    let usesUITestData: Bool

    /// The launch configuration derived from the current process arguments.
    static let current = AppLaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)

    // MARK: - Initialization

    /// Creates a launch configuration from process arguments.
    ///
    /// - Parameter arguments: The raw process arguments passed at launch.
    init(arguments: [String]) {
        skipsSplash = arguments.contains("--skip-splash")
        usesUITestData = arguments.contains("--ui-testing")
    }
}
