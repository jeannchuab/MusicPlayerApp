import SwiftUI
import SwiftData

struct AppDependencies {
    static let live = AppDependencies.makeLive()

    let launchConfiguration: AppLaunchConfiguration
    let baselineStatus: String
    let songRepository: any SongRepository
    let modelContainer: ModelContainer
    let makeAudioPlaybackService: @MainActor () -> any AudioPlaybackService

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

private struct AppDependenciesKey: EnvironmentKey {
    static let defaultValue = AppDependencies.live
}

extension EnvironmentValues {
    var appDependencies: AppDependencies {
        get { self[AppDependenciesKey.self] }
        set { self[AppDependenciesKey.self] = newValue }
    }
}
