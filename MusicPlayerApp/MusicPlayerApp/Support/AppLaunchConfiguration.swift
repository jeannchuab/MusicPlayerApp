import Foundation

/// Captures launch-time flags that alter app behavior for tests and local runs.
struct AppLaunchConfiguration {

    // MARK: - Supporting Types

    /// The fixture dataset mode used when deterministic UI-test data is enabled.
    enum FixtureMode: String {

        // MARK: - Cases

        /// Returns the standard set of fixture songs.
        case standard

        /// Returns an empty initial feed and empty search results.
        case empty

        /// Forces repository calls to fail with a transport error.
        case error
    }

    // MARK: - Properties

    /// Indicates whether the splash screen should be skipped.
    let skipsSplash: Bool

    /// Indicates whether deterministic UI test data should be used.
    let usesUITestData: Bool

    /// The fixture data mode used when deterministic UI-test data is enabled.
    let fixtureMode: FixtureMode

    /// The launch configuration derived from the current process arguments.
    static let current = AppLaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)

    // MARK: - Initialization

    /// Creates a launch configuration from process arguments.
    ///
    /// - Parameter arguments: The raw process arguments passed at launch.
    init(arguments: [String]) {
        skipsSplash = arguments.contains("--skip-splash")
        usesUITestData = arguments.contains("--ui-testing")
        if arguments.contains("--ui-testing-empty") {
            fixtureMode = .empty
        } else if arguments.contains("--ui-testing-error") {
            fixtureMode = .error
        } else {
            fixtureMode = .standard
        }
    }
}
