import Foundation
import Testing
@testable import NetworkMenuBarKit

private enum StubResponse {
    case body(String, status: Int = 200)
    case failure(URLError.Code)
}

private final class StubURLProtocol: URLProtocol {
    nonisolated(unsafe) private static var responses: [String: StubResponse] = [:]
    nonisolated(unsafe) private static var requestedHosts: [String] = []
    private static let lock = NSLock()

    static func reset(_ responses: [String: StubResponse]) {
        lock.withLock {
            self.responses = responses
            requestedHosts = []
        }
    }

    static var hosts: [String] { lock.withLock { requestedHosts } }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }
    override func stopLoading() {}

    override func startLoading() {
        let url = request.url!
        let response = Self.lock.withLock {
            Self.requestedHosts.append(url.host()!)
            return Self.responses[url.host()!]
        }
        switch response {
        case .body(let body, let status):
            let http = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
            client?.urlProtocol(self, didReceive: http, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: Data(body.utf8))
            client?.urlProtocolDidFinishLoading(self)
        case .failure(let code):
            client?.urlProtocol(self, didFailWithError: URLError(code))
        case nil:
            client?.urlProtocol(self, didFailWithError: URLError(.cannotFindHost))
        }
    }
}

@Suite(.serialized)
struct PublicIPServiceTests {
    private let service: PublicIPService = {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubURLProtocol.self]
        return PublicIPService(session: URLSession(configuration: configuration))
    }()

    @Test func defaultEndpointsInOrder() {
        #expect(PublicIPService.defaultEndpoints.map(\.absoluteString) == [
            "https://api.ipify.org",
            "https://checkip.amazonaws.com",
            "https://ipv4.icanhazip.com",
        ])
    }

    @Test func returnsTrimmedAddressFromFirstEndpoint() async throws {
        StubURLProtocol.reset(["api.ipify.org": .body("85.12.34.201\n")])

        #expect(try await service.fetchPublicIP() == "85.12.34.201")
        #expect(StubURLProtocol.hosts == ["api.ipify.org"])
    }

    @Test func fallsBackWhenFirstReturnsHTML() async throws {
        StubURLProtocol.reset([
            "api.ipify.org": .body("<html>Login to Wi-Fi</html>"),
            "checkip.amazonaws.com": .body("85.12.34.201\n"),
        ])

        #expect(try await service.fetchPublicIP() == "85.12.34.201")
    }

    @Test func fallsBackOnHTTPError() async throws {
        StubURLProtocol.reset([
            "api.ipify.org": .body("85.12.34.201", status: 503),
            "checkip.amazonaws.com": .failure(.timedOut),
            "ipv4.icanhazip.com": .body("85.12.34.201\n"),
        ])

        #expect(try await service.fetchPublicIP() == "85.12.34.201")
        #expect(StubURLProtocol.hosts == ["api.ipify.org", "checkip.amazonaws.com", "ipv4.icanhazip.com"])
    }

    @Test func rejectsIPv6Response() async throws {
        StubURLProtocol.reset([
            "api.ipify.org": .body("2001:db8::1"),
            "checkip.amazonaws.com": .body("85.12.34.201"),
        ])

        #expect(try await service.fetchPublicIP() == "85.12.34.201")
    }

    @Test func throwsWhenAllFail() async {
        StubURLProtocol.reset([
            "api.ipify.org": .failure(.notConnectedToInternet),
            "checkip.amazonaws.com": .failure(.notConnectedToInternet),
            "ipv4.icanhazip.com": .failure(.notConnectedToInternet),
        ])

        await #expect(throws: PublicIPError.allEndpointsFailed) {
            try await service.fetchPublicIP()
        }
    }

    @Test func defaultSessionTimeoutIsFiveSeconds() {
        #expect(URLSession.ephemeralWithTimeout.configuration.timeoutIntervalForRequest == 5)
    }
}
