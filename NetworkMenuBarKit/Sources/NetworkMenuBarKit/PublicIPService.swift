import Foundation

public protocol PublicIPFetching: Sendable {
    func fetchPublicIP() async throws -> String
}

public enum PublicIPError: Error, Equatable {
    case allEndpointsFailed
    case timedOut
}

public struct PublicIPService: PublicIPFetching {
    public static let defaultEndpoints = [
        URL(string: "https://checkip.amazonaws.com")!,
        URL(string: "https://api.ipify.org")!,
        URL(string: "https://ipv4.icanhazip.com")!,
    ]

    public static let defaultDeadline: Duration = .seconds(5)

    private let endpoints: [URL]
    private let configuration: URLSessionConfiguration
    private let deadline: Duration

    public init(
        endpoints: [URL] = defaultEndpoints,
        configuration: URLSessionConfiguration = .publicIPLookup,
        deadline: Duration = defaultDeadline
    ) {
        self.endpoints = endpoints
        self.configuration = configuration
        self.deadline = deadline
    }

    /// Tries each endpoint in order and returns the first response that is a public IPv4 address,
    /// giving up after `deadline` in total.
    public func fetchPublicIP() async throws -> String {
        // A new session per lookup so no connection opened on the previous network is reused.
        let session = URLSession(configuration: configuration)
        defer { session.invalidateAndCancel() }
        return try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask { try await firstValidAddress(using: session) }
            group.addTask { [deadline] in
                try await Task.sleep(for: deadline)
                throw PublicIPError.timedOut
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    private func firstValidAddress(using session: URLSession) async throws -> String {
        for endpoint in endpoints {
            try Task.checkCancellation()
            guard let (data, response) = try? await session.data(from: endpoint),
                  (response as? HTTPURLResponse)?.statusCode == 200 else { continue }

            let body = String(decoding: data, as: UTF8.self).trimmingCharacters(in: .whitespacesAndNewlines)
            if isPublicIPv4(body) {
                return body
            }
        }
        try Task.checkCancellation()
        throw PublicIPError.allEndpointsFailed
    }
}

extension URLSessionConfiguration {
    public static var publicIPLookup: URLSessionConfiguration {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForRequest = 5
        configuration.httpCookieStorage = nil
        configuration.httpShouldSetCookies = false
        configuration.httpCookieAcceptPolicy = .never
        configuration.urlCache = nil
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        return configuration
    }
}
