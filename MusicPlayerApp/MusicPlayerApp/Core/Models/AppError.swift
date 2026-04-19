import Foundation

enum AppError: Error, Equatable, Sendable {
    case invalidURL
    case emptySearchTerm
    case invalidResponse
    case httpStatus(Int)
    case decodingFailed
    case transport(String)
    case unknown(String)
}

extension AppError {
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
