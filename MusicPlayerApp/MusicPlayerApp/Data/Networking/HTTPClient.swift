import Foundation

/// Defines the HTTP transport used by the data layer.
protocol HTTPClient: Sendable {

    /// Loads the raw data and HTTP response for the given URL.
    ///
    /// - Parameter url: The endpoint URL to request.
    func data(from url: URL) async throws -> (Data, HTTPURLResponse)
}

/// A production ``HTTPClient`` backed by `URLSession`.
struct URLSessionHTTPClient: HTTPClient {

    // MARK: - Properties

    /// The URL session used to execute HTTP requests.
    private let session: URLSession

    // MARK: - Initialization

    /// Creates a URLSession-backed HTTP client.
    ///
    /// - Parameter session: The URL session used to execute requests.
    init(session: URLSession = .shared) {
        self.session = session
    }

    // MARK: - HTTPClient

    /// Loads the raw data and HTTP response for the given URL.
    ///
    /// - Parameter url: The endpoint URL to request.
    func data(from url: URL) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await session.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw AppError.invalidResponse
        }

        return (data, httpResponse)
    }
}
