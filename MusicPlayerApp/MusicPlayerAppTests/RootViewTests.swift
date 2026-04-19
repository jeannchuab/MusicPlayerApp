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
    }
}
