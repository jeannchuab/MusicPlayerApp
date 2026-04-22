import Testing
@testable import MusicPlayerApp

/// Coverage tests for user-facing app error messages.
struct AppErrorTests {

    // MARK: - Tests

    @Test func userMessageCoversAllErrorCases() {
        #expect(AppError.invalidURL.userMessage == "We could not create a valid request.")
        #expect(AppError.emptySearchTerm.userMessage == "Type an artist, song, or album to search.")
        #expect(AppError.invalidResponse.userMessage == "The server response was not valid.")
        #expect(AppError.httpStatus(503).userMessage == "The music service is unavailable right now.")
        #expect(AppError.decodingFailed.userMessage == "We could not read the music results.")
        #expect(AppError.transport("Offline").userMessage == "Check your connection and try again.")
        #expect(AppError.unknown("Boom").userMessage == "Something went wrong. Please try again.")
    }
}
