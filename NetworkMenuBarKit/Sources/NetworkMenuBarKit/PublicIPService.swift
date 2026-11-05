import Foundation
import Network

public protocol PublicIPFetching: Sendable {
    func fetchPublicIP() async throws -> String
}

public enum PublicIPError: Error, Equatable {
    case allEndpointsFailed
}

public struct PublicIPService: PublicIPFetching {
    public static let defaultEndpoints = [
        URL(string: "https://checkip.amazonaws.com")!,
        URL(string: "https://api.ipify.org")!,
        URL(string: "https://ipv4.icanhazip.com")!,
    ]

    private let endpoints: [URL]
    private let session: URLSession

    public init(endpoints: [URL] = defaultEndpoints, session: URLSession = .ephemeralWithTimeout) {
        self.endpoints = endpoints
        self.session = session
    }

    /// Tries each endpoint in order and returns the first response that is a valid IPv4 address.
    public func fetchPublicIP() async throws -> String {
        for endpoint in endpoints {
            try Task.checkCancellation()
            guard let (data, response) = try? await session.data(from: endpoint),
                  (response as? HTTPURLResponse)?.statusCode == 200 else { continue }

            let body = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            if IPv4Address(body) != nil {
                return body
            }
        }
        try Task.checkCancellation()
        throw PublicIPError.allEndpointsFailed
    }
}

extension URLSession {
    public static let ephemeralWithTimeout: URLSession = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        return URLSession(configuration: configuration)
    }()
}
