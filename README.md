# MusicPlayerApp

MusicPlayerApp is an iPhone-focused SwiftUI implementation

## Challenge Scope

- Swift 6
- SwiftUI
- MVVM
- Swift concurrency
- iTunes Search API integration
- SwiftData cache in a later implementation step
- Automated tests
- iPhone UI based on the provided Figma flow
- Optional extras: error states, swipe to refresh, organized repository, player controls, timeline seek, and accessibility

Dedicated iPad UI/UX is intentionally out of scope for this implementation plan.

## Architecture Direction

The app is organized around feature-first MVVM with protocol-based dependencies:

- `Core`: domain concepts shared across features.
- `Data`: API, persistence, DTO mapping, and repositories.
- `DesignSystem`: reusable colors, typography, and UI primitives.
- `Features`: user-facing flows such as Home, Player, Album, and shared sheets.
- `Support`: dependency container and environment wiring.

Step 1 leaves the app on a temporary root screen while the architecture and project baseline are prepared.

## Step 2: Domain And Network Baseline

The first real data boundary is in place:

- `Song`, `Album`, `SearchPage`, `LoadableState`, and `AppError` describe app-facing domain data.
- `MusicSearchService`, `AlbumLookupService`, and `SongRepository` keep features independent from concrete API implementations.
- `ITunesSearchClient` talks to the iTunes Search API using `async/await` and an injectable `HTTPClient`.
- iTunes DTOs are mapped into domain models before leaving the data layer.
- Unit fixtures cover search and album lookup responses without relying on live network calls.

## Step 3: Repository And Offline Cache

The repository layer now composes the live iTunes client with a SwiftData cache:

- `CachedSongRepository` saves successful search and album responses.
- `SwiftDataSongCacheStore` stores songs, search pages, and albums for offline fallback.
- Feature code depends on `SongRepository`, so the data source can be swapped in tests or future API changes.

## Step 4: Home Search Experience

The first user-facing screen is now in place:

- `HomeViewModel` owns search, refresh, pagination, selection, loading, empty, and error states.
- `HomeView` renders a searchable song list with artwork, pull-to-refresh, infinite scroll, and retry handling.
- Selecting a song opens the dedicated player experience.

## Step 5: Player Experience

The dedicated player screen is now connected from the song list:

- `PlayerViewModel` owns playback loading, play/pause, timeline seek, progress updates, and formatted time state.
- `AVAudioPlaybackService` wraps `AVPlayer` behind `AudioPlaybackService`, keeping the player replaceable in tests.
- `PlayerView` presents artwork, song metadata, timeline controls, playback controls, and a more-options bottom sheet.

## Step 6: Album Experience

Album navigation is now connected from the player more-options sheet:

- `AlbumViewModel` loads album details through `SongRepository.lookupAlbum`.
- `AlbumView` renders album artwork, title, artist, track count, refresh, error handling, and playable tracks.
- Album track selection opens the same dedicated player flow, keeping playback behavior consistent.

## Step 7: Recently Played

Recently played support now uses the existing SwiftData cache:

- `SongRepository` exposes recently played reads and writes.
- `SwiftDataSongCacheStore` stores the latest play timestamp per song and returns the most recent songs first.
- The Home screen shows a horizontal Recently Played section after the user opens songs.

## Step 8: Splash And Launch Flow

The app now starts with a lightweight splash experience:

- `SplashView` introduces the app before transitioning into Home.
- `AppLaunchConfiguration` centralizes launch flags for UI tests and local diagnostics.
- UI tests can skip the splash and use fixture data with `--ui-testing --skip-splash`.

## Step 9: Final Evaluation Polish

The implementation now has evaluation-facing polish:

- Key screens and states have accessibility identifiers for UI automation.
- Song rows and player controls include clearer accessibility labels and values.
- UI tests launch against deterministic fixture data instead of live API calls.

## Running The Project

- Open `MusicPlayerApp/MusicPlayerApp.xcodeproj` in Xcode.
- Select the `MusicPlayerApp` scheme.
- Run on an iPhone simulator or device using iOS 17.6 or newer.

## Verification

The main verification commands used during implementation are:

```bash
xcodebuild build -project MusicPlayerApp/MusicPlayerApp.xcodeproj -scheme MusicPlayerApp -destination generic/platform=iOS -derivedDataPath /tmp/MusicPlayerAppDerivedData CODE_SIGNING_ALLOWED=NO
xcodebuild build-for-testing -project MusicPlayerApp/MusicPlayerApp.xcodeproj -scheme MusicPlayerApp -destination generic/platform=iOS -derivedDataPath /tmp/MusicPlayerAppDerivedData CODE_SIGNING_ALLOWED=NO
```

## Trade-offs

- The iTunes Search API provides preview clips, so playback is limited to the available preview URL rather than full songs.
- SwiftData is used as an offline fallback cache for search, album details, and recently played songs.
- Dedicated iPad UI remains intentionally out of scope; the SwiftUI layout is compatible, but the design target is iPhone.
