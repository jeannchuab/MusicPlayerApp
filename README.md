# MusicPlayerApp

MusicPlayerApp is a SwiftUI music browsing and preview experience built for the Music AI / Moises iPhone code challenge. The application integrates with the iTunes Search API, supports preview playback, persists cached data locally, and follows a feature-first MVVM structure with protocol-based boundaries and Swift Concurrency.

## References

- Requirement: [Music AI iPhone Challenge](https://moisesai.notion.site/iPhone-31f143d913108013a685dd9af4f657cb)
- Figma design: [Code Challenge](https://www.figma.com/design/uuhUN9OZYqNZkBxuDq9FWh/Code-Challenge?node-id=10985-10110&t=etEwvDfga5a2EMBw-4)
- iTunes API reference: [iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/UnderstandingSearchResults.html#//apple_ref/doc/uid/TP40017632-CH8-SW1)

## Platform

- Swift 6
- SwiftUI
- Minimum iOS version: `iOS 26.0`
- Device support in this submission: `iPhone only`

This implementation is intentionally optimized for the iPhone experience defined in the provided Figma. A dedicated iPad layout is not included in the current scope.

## Features

- Search-based song discovery powered by the iTunes Search API
- Preview playback using `AVPlayer`
- Album details flow from player and song options
- Recently played history
- Offline-friendly cache for search results, albums, and playback history using SwiftData
- Custom bottom sheet interactions for song options

## Extra Points Implemented

- Share option
- Repeat song option
- Forward and backward track actions
- Drag-to-seek playback position
- Accessibility support
- Empty state screens

## Architecture

The project is organized around feature-first MVVM with clear separation between domain, data, design system, and UI layers.

- `Core`: domain models and protocols
- `Data`: API integration, DTOs, mappers, repositories, playback, and caching
- `DesignSystem`: typography and colors
- `Features`: Home, Player, Album, Splash, Root, and shared UI components
- `Support`: dependency wiring, launch configuration, fixtures, and environment integration

Protocol-based abstractions keep feature code isolated from implementation details:

- `SongRepository`
- `MusicSearchService`
- `AlbumLookupService`
- `AudioPlaybackService`
- `HTTPClient`

The production repository uses live iTunes services plus a SwiftData-backed cache fallback.

## Swift Concurrency

Swift Concurrency is used throughout the app:

- `async/await` for network and repository operations
- `@MainActor` isolation for UI-facing state and services
- SwiftUI `.task` for screen lifecycle-driven loading
- `Task` usage for async UI-triggered operations such as search and playback updates

## Running The App

1. Open [MusicPlayerApp.xcodeproj](/Users/jeannchuab/Projects/jeannchuab/MusicPlayerApp/MusicPlayerApp/MusicPlayerApp.xcodeproj)
2. Select the `MusicPlayerApp` scheme
3. Choose an iPhone simulator running iOS 26.0 or newer
4. Build and run

## Running Tests

Run from Xcode using `Product > Test`, or use:

```bash
xcodebuild build -project MusicPlayerApp/MusicPlayerApp.xcodeproj -scheme MusicPlayerApp -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO
xcodebuild build-for-testing -project MusicPlayerApp/MusicPlayerApp.xcodeproj -scheme MusicPlayerApp -destination generic/platform=iOS CODE_SIGNING_ALLOWED=NO
```

UI tests support deterministic launch behavior through launch arguments:

- `--ui-testing`: launches the app with fixture data and silent playback services instead of live API-dependent behavior
- `--skip-splash`: skips the splash screen delay so UI tests start directly in the main flow

## Notes

- Playback uses the preview URLs returned by the iTunes Search API, so full-length songs are not available.
- The iTunes Search API does not provide documented server-side pagination beyond `limit`, so the app fetches a larger search result batch and paginates locally.
- Search, album data, and recently played songs are cached to improve resilience and support fallback behavior.
- The Home, Player, and Album flows share a reusable song options sheet component.

## Screenshots

### Home

<img width="482" height="1049" alt="HomeView(1)" src="https://github.com/user-attachments/assets/ab6c2b36-4aa4-436d-8b6e-08dd59a40a72" />
<img width="482" height="1049" alt="HomeView(2)" src="https://github.com/user-attachments/assets/8a2e46b1-fbd0-41c3-b401-3f8de1d852d9" />

### Player

<img width="482" height="1049" alt="Player(1)" src="https://github.com/user-attachments/assets/82934330-ead1-4041-931f-e29d1de30db5" />
<img width="482" height="1049" alt="Player(2)" src="https://github.com/user-attachments/assets/b8c89c4e-4dd7-473a-910a-8d658727f4c1" />
<img width="482" height="1049" alt="Player(3)" src="https://github.com/user-attachments/assets/9419ab71-f4a4-4dac-a884-3f03aff97709" />
<img width="482" height="1049" alt="Player(4)" src="https://github.com/user-attachments/assets/09d0c23f-254b-420f-ab0b-ae903e8fec8e" />
<img width="482" height="1049" alt="Player(5)" src="https://github.com/user-attachments/assets/dada5d08-4367-4781-9dd9-6022fe2d4ad8" />

### Album

<img width="482" height="1049" alt="Album(1)" src="https://github.com/user-attachments/assets/06d9ea67-b45f-4623-98cd-b4a66e1b6207" />

### Splash

<img width="482" height="1049" alt="Splash(1)" src="https://github.com/user-attachments/assets/58a64473-c6ba-4e3c-a0c0-59c391cbd48c" />

