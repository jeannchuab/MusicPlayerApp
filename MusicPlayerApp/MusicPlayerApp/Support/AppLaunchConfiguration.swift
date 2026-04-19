import Foundation

struct AppLaunchConfiguration {
    let skipsSplash: Bool
    let usesUITestData: Bool

    static let current = AppLaunchConfiguration(arguments: ProcessInfo.processInfo.arguments)

    init(arguments: [String]) {
        skipsSplash = arguments.contains("--skip-splash")
        usesUITestData = arguments.contains("--ui-testing")
    }
}
