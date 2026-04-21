import SwiftUI
import SwiftData

/// Groups the shared dependencies required by the app and exposes environment integration.
struct AppDependencies {

    // MARK: - Properties

    /// The live dependency container used by the running app.
    static let live = AppDependencies.makeLive()

    /// The launch configuration derived from process arguments.
    let launchConfiguration: AppLaunchConfiguration

    /// A lightweight readiness string used during app setup.
    let baselineStatus: String

    /// The repository used by feature screens for search and playback history.
    let songRepository: any SongRepository

    /// The shared SwiftData model container.
    let modelContainer: ModelContainer

    /// Factory used to create a fresh playback service on demand.
    let makeAudioPlaybackService: @MainActor () -> any AudioPlaybackService

    // MARK: - Factory

    /// Builds the live app dependency container.
    private static func makeLive() -> AppDependencies {
        let launchConfiguration = AppLaunchConfiguration.current
        let container = makeModelContainer()
        if launchConfiguration.usesUITestData {
            return AppDependencies(
                launchConfiguration: launchConfiguration,
                baselineStatus: "UI test data ready",
                songRepository: FixtureSongRepository(),
                modelContainer: container,
                makeAudioPlaybackService: { SilentAudioPlaybackService() }
            )
        }

        let searchClient = ITunesSearchClient()
        let cacheStore = SwiftDataSongCacheStore(context: ModelContext(container))
        let repository = CachedSongRepository(
            searchService: searchClient,
            albumLookupService: searchClient,
            cacheStore: cacheStore
        )

        return AppDependencies(
            launchConfiguration: launchConfiguration,
            baselineStatus: "Data and home feed ready",
            songRepository: repository,
            modelContainer: container,
            makeAudioPlaybackService: { AVAudioPlaybackService() }
        )
    }

    /// Builds the SwiftData model container used by the app.
    private static func makeModelContainer() -> ModelContainer {
        let schema = Schema([
            CachedSongEntity.self,
            CachedSearchPageEntity.self,
            CachedAlbumEntity.self
        ])

        do {
            return try ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema)]
            )
        } catch {
            return try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)]
            )
        }
    }
}

/// Environment key used to inject ``AppDependencies`` into SwiftUI views.
private struct AppDependenciesKey: EnvironmentKey {

    // MARK: - Properties

    /// The default dependency container used when no custom environment value is supplied.
    static let defaultValue = AppDependencies.live
}

/// Environment integration for accessing ``AppDependencies`` from SwiftUI views.
extension EnvironmentValues {
    /// The app dependency container available to SwiftUI views.
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
