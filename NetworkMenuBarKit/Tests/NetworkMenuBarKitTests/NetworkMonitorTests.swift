import Testing
@testable import NetworkMenuBarKit

private struct FakeReader: SystemStateReading {
    var state: SystemState

    func read() -> SystemState { state }
}

private struct FetchFailed: Error {}

private actor FakeFetcher: PublicIPFetching {
    private var script: [(result: Result<String, any Error>, delay: Duration)]
    private(set) var calls = 0

    init(_ script: [(result: Result<String, any Error>, delay: Duration)]) {
        self.script = script
    }

    func fetchPublicIP() async throws -> String {
        calls += 1
        let (result, delay) = script.isEmpty ? (.failure(FetchFailed()), .zero) : script.removeFirst()
        // Ignores cancellation on purpose, like a slow server that answers anyway.
        try? await Task.sleep(for: delay)
        return try result.get()
    }
}

private let onWifi = SystemState(
    addresses: ["en0": ["192.168.1.34"]],
    hardwarePorts: [HardwarePort(bsdName: "en0", kind: .wifi, localizedName: "Wi-Fi")],
    primaryInterface: "en0"
)

private let offline = SystemState(
    hardwarePorts: [HardwarePort(bsdName: "en0", kind: .wifi, localizedName: "Wi-Fi")]
)

@MainActor
struct NetworkMonitorTests {
    @Test func refreshPublishesInterfacesAndPublicIP() async {
        let monitor = NetworkMonitor(reader: FakeReader(state: onWifi), publicIPFetcher: FakeFetcher([(.success("85.12.34.201"), .zero)]))

        monitor.refresh()
        await monitor.fetchTask?.value

        #expect(monitor.connection == .wifi)
        #expect(monitor.interfaces.map(\.bsdName) == ["en0"])
        #expect(monitor.primaryInterface == "en0")
        #expect(monitor.viaInterface?.bsdName == "en0")
        #expect(monitor.publicIP == .available("85.12.34.201"))
    }

    @Test func fetchFailureBecomesUnavailable() async {
        let monitor = NetworkMonitor(reader: FakeReader(state: onWifi), publicIPFetcher: FakeFetcher([(.failure(FetchFailed()), .zero)]))

        monitor.refresh()
        await monitor.fetchTask?.value

        #expect(monitor.publicIP == .unavailable)
    }

    @Test func loadingKeepsPreviousAddress() async {
        let fetcher = FakeFetcher([(.success("1.1.1.1"), .zero), (.success("2.2.2.2"), .milliseconds(200))])
        let monitor = NetworkMonitor(reader: FakeReader(state: onWifi), publicIPFetcher: fetcher)

        monitor.refresh()
        await monitor.fetchTask?.value
        monitor.refresh()

        #expect(monitor.publicIP == .loading(previous: "1.1.1.1"))
        await monitor.fetchTask?.value
        #expect(monitor.publicIP == .available("2.2.2.2"))
    }

    @Test func staleFetchDoesNotOverwriteNewer() async {
        let fetcher = FakeFetcher([(.success("1.1.1.1"), .milliseconds(300)), (.success("2.2.2.2"), .zero)])
        let monitor = NetworkMonitor(reader: FakeReader(state: onWifi), publicIPFetcher: fetcher)

        monitor.refresh()
        let stale = monitor.fetchTask
        monitor.refresh()
        await monitor.fetchTask?.value
        await stale?.value

        #expect(monitor.publicIP == .available("2.2.2.2"))
    }

    @Test func burstOfChangesFetchesOnce() async {
        let fetcher = FakeFetcher([(.success("85.12.34.201"), .zero)])
        let monitor = NetworkMonitor(reader: FakeReader(state: onWifi), publicIPFetcher: fetcher, debounce: .milliseconds(50))

        for _ in 0..<5 {
            monitor.scheduleRefresh()
            try? await Task.sleep(for: .milliseconds(10))
        }
        await monitor.pendingRefresh?.value
        await monitor.fetchTask?.value

        #expect(await fetcher.calls == 1)
        #expect(monitor.publicIP == .available("85.12.34.201"))
    }

    @Test func startShowsInterfacesImmediatelyWithoutFetching() async {
        let fetcher = FakeFetcher([(.success("85.12.34.201"), .zero)])
        let monitor = NetworkMonitor(reader: FakeReader(state: onWifi), publicIPFetcher: fetcher, debounce: .seconds(60))

        monitor.start()

        #expect(monitor.connection == .wifi)
        #expect(monitor.publicIP == .loading(previous: nil))
        #expect(await fetcher.calls == 0)
    }

    @Test func offlineBecomesUnavailableWithoutFetching() async {
        let fetcher = FakeFetcher([(.success("85.12.34.201"), .zero)])
        let monitor = NetworkMonitor(reader: FakeReader(state: offline), publicIPFetcher: fetcher)

        monitor.refresh()
        await monitor.fetchTask?.value

        #expect(monitor.connection == .offline)
        #expect(monitor.publicIP == .unavailable)
        #expect(await fetcher.calls == 0)
    }
}
