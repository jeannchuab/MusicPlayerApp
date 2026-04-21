import Foundation

/// Domain errors surfaced throughout the app, covering networking, decoding, and general failures.
///
/// Each case maps to a human-readable message via the ``userMessage`` computed property,
/// which is displayed directly in ``ErrorStateView``.
enum AppError: Error, Equatable, Sendable {

    /// The constructed URL was malformed or `nil`.
    case invalidURL

    /// The user submitted a blank search query.
    case emptySearchTerm

    /// The server returned a non-HTTP or otherwise unrecognisable response.
    case invalidResponse

    /// The server responded with a non-success HTTP status code.
    case httpStatus(Int)

    /// JSON decoding of the response body failed.
    case decodingFailed

    /// A transport-level error occurred (e.g. no network). The associated value is a description.
    case transport(String)

    /// A catch-all for unexpected errors. The associated value is a description.
    case unknown(String)
}

extension AppError {

    /// A user-facing message suitable for display in error views.
    var userMessage: String {
        switch self {
        case .invalidURL:
            "We could not create a valid request."
        case .emptySearchTerm:
            "Type an artist, song, or album to search."
        case .invalidResponse:
            "The server response was not valid."
        case .httpStatus:
            "The music service is unavailable right now."
        case .decodingFailed:
            "We could not read the music results."
        case .transport:
            "Check your connection and try again."
        case .unknown:
            "Something went wrong. Please try again."
        }
    }
}
