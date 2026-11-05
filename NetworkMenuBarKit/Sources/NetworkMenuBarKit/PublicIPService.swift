import Foundation
import Network

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
    private let session: URLSession
    private let deadline: Duration

    public init(
        endpoints: [URL] = defaultEndpoints,
        session: URLSession = .ephemeralWithTimeout,
        deadline: Duration = defaultDeadline
    ) {
        self.endpoints = endpoints
        self.session = session
        self.deadline = deadline
    }

    /// Tries each endpoint in order and returns the first response that is a valid IPv4 address,
    /// giving up after `deadline` in total.
    public func fetchPublicIP() async throws -> String {
        try await withThrowingTaskGroup(of: String.self) { group in
            group.addTask { try await firstValidAddress() }
            group.addTask { [deadline] in
                try await Task.sleep(for: deadline)
                throw PublicIPError.timedOut
            }
            defer { group.cancelAll() }
            return try await group.next()!
        }
    }

    private func firstValidAddress() async throws -> String {
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
