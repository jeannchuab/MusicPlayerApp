import Foundation
import Testing
@testable import MusicPlayerApp

/// Coverage tests for the production URLSession-backed HTTP client.
@MainActor
struct HTTPClientTests {

    // MARK: - Tests

    @Test func dataReturnsResponseDataAndHTTPURLResponse() async throws {
        let expectedData = Data("hello".utf8)
        let session = makeSession { request in
            let response = HTTPURLResponse(
                url: try #require(request.url),
                statusCode: 200,
                httpVersion: nil,
                headerFields: nil
            )
            return (expectedData, response, nil)
        }
        let client = URLSessionHTTPClient(session: session)

        let (data, response) = try await client.data(from: try #require(URL(string: "https://example.com")))

        #expect(data == expectedData)
        #expect(response.statusCode == 200)
    }

    // MARK: - Helpers

    /// Builds a URLSession configured to respond through `MockURLProtocol`.
    ///
    /// - Parameter handler: The request handler invoked by the mock URL protocol.
    /// - Returns: An ephemeral `URLSession` configured for the test case.
    private func makeSession(
        handler: @escaping @Sendable (URLRequest) throws -> (Data, URLResponse?, Error?)
    ) -> URLSession {
        MockURLProtocol.handler = handler
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: configuration)
    }
}

/// A URL protocol test double that returns deterministic responses to URLSession requests.
@MainActor
private final class MockURLProtocol: URLProtocol, @unchecked Sendable {

    // MARK: - Properties

    /// The request handler used to produce deterministic responses for each request.
    nonisolated(unsafe) static var handler: (@Sendable (URLRequest) throws -> (Data, URLResponse?, Error?))?

    // MARK: - URLProtocol

    /// Indicates that the mock can intercept any request.
    ///
    /// - Parameter request: The request being evaluated.
    /// - Returns: `true` for all requests.
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    /// Returns the request unchanged.
    ///
    /// - Parameter request: The intercepted request.
    /// - Returns: The same request instance.
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    /// Starts loading the mocked response for the intercepted request.
    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        do {
            let (data, response, error) = try handler(request)

            if let response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }

            if let error {
                client?.urlProtocol(self, didFailWithError: error)
            } else {
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            }
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    /// Stops loading the mocked request.
    override func stopLoading() {}
}
