import Testing
@testable import MusicPlayerApp

struct RootViewTests {
    @MainActor
    @Test func launchConfigurationReadsUITestFlags() {
        let configuration = AppLaunchConfiguration(arguments: ["MusicPlayerApp", "--ui-testing", "--skip-splash"])

        #expect(configuration.usesUITestData)
        #expect(configuration.skipsSplash)
    }

    @MainActor
    @Test func launchConfigurationDefaultsToProductionFlow() {
        let configuration = AppLaunchConfiguration(arguments: ["MusicPlayerApp"])

        #expect(configuration.usesUITestData == false)
        #expect(configuration.skipsSplash == false)
        #expect(configuration.fixtureMode == .standard)
    }

    @MainActor
    @Test func launchConfigurationReadsFixtureModes() {
        let emptyConfiguration = AppLaunchConfiguration(arguments: ["MusicPlayerApp", "--ui-testing", "--ui-testing-empty"])
        let errorConfiguration = AppLaunchConfiguration(arguments: ["MusicPlayerApp", "--ui-testing", "--ui-testing-error"])

        #expect(emptyConfiguration.fixtureMode == .empty)
        #expect(errorConfiguration.fixtureMode == .error)
    }
}
