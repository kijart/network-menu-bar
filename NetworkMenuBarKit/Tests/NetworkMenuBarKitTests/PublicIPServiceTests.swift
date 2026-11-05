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
            "https://checkip.amazonaws.com",
            "https://api.ipify.org",
            "https://ipv4.icanhazip.com",
        ])
    }

    @Test func returnsTrimmedAddressFromAWS() async throws {
        StubURLProtocol.reset(["checkip.amazonaws.com": .body("85.12.34.201\n")])

        #expect(try await service.fetchPublicIP() == "85.12.34.201")
        #expect(StubURLProtocol.hosts == ["checkip.amazonaws.com"])
    }

    @Test func fallsBackWhenFirstReturnsHTML() async throws {
        StubURLProtocol.reset([
            "checkip.amazonaws.com": .body("<html>Login to Wi-Fi</html>"),
            "api.ipify.org": .body("85.12.34.201\n"),
        ])

        #expect(try await service.fetchPublicIP() == "85.12.34.201")
    }

    @Test func fallsBackOnHTTPError() async throws {
        StubURLProtocol.reset([
            "checkip.amazonaws.com": .body("85.12.34.201", status: 503),
            "api.ipify.org": .failure(.timedOut),
            "ipv4.icanhazip.com": .body("85.12.34.201\n"),
        ])

        #expect(try await service.fetchPublicIP() == "85.12.34.201")
        #expect(StubURLProtocol.hosts == ["checkip.amazonaws.com", "api.ipify.org", "ipv4.icanhazip.com"])
    }

    @Test func rejectsIPv6Response() async throws {
        StubURLProtocol.reset([
            "checkip.amazonaws.com": .body("2001:db8::1"),
            "api.ipify.org": .body("85.12.34.201"),
        ])

        #expect(try await service.fetchPublicIP() == "85.12.34.201")
    }

    @Test func throwsWhenAllFail() async {
        StubURLProtocol.reset([
            "checkip.amazonaws.com": .failure(.notConnectedToInternet),
            "api.ipify.org": .failure(.notConnectedToInternet),
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
