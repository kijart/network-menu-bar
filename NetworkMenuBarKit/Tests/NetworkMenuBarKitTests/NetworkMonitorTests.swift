import Foundation
import Testing
@testable import NetworkMenuBarKit

private struct FakeReader: SystemStateReading {
    var state: SystemState

    func read() -> SystemState { state }
}

private final class SwitchableReader: SystemStateReading, @unchecked Sendable {
    var state: SystemState

    init(_ state: SystemState) { self.state = state }

    func read() -> SystemState { state }
}

private final class SlowReader: SystemStateReading, @unchecked Sendable {
    var state: SystemState
    var delay: TimeInterval = 0

    init(_ state: SystemState) { self.state = state }

    func read() -> SystemState {
        let (state, delay) = (state, delay)
        Thread.sleep(forTimeInterval: delay)
        return state
    }
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

private let vpnOnly = SystemState(
    addresses: ["utun4": ["10.8.0.2"]],
    hardwarePorts: [HardwarePort(bsdName: "en0", kind: .wifi, localizedName: "Wi-Fi")],
    vpnServices: [VPNService(name: "Home Lab", providerBundleID: "com.wireguard.macos", bsdName: "utun4")],
    primaryInterface: "utun4"
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

    @Test func viaFollowsFullTunnelRoute() async {
        var fullTunnel = vpnOnly
        fullTunnel.addresses["en0"] = ["192.168.1.34"]
        fullTunnel.primaryInterface = "en0"
        fullTunnel.routeInterface = "utun4"
        let monitor = NetworkMonitor(reader: FakeReader(state: fullTunnel), publicIPFetcher: FakeFetcher([]))

        monitor.reloadInterfaces()
        await monitor.readTask?.value

        #expect(monitor.viaInterface?.bsdName == "utun4")
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
        while await fetcher.calls == 0 { await Task.yield() }
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
        await monitor.readTask?.value

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

    @Test func unsatisfiedPathIsOfflineEvenWithAVPNTunnel() async {
        let fetcher = FakeFetcher([(.success("85.12.34.201"), .zero)])
        let monitor = NetworkMonitor(reader: FakeReader(state: vpnOnly), publicIPFetcher: fetcher, debounce: .zero)

        monitor.pathChanged(satisfied: false)
        await monitor.pendingRefresh?.value
        await monitor.fetchTask?.value

        #expect(monitor.connection == .offline)
        #expect(monitor.publicIP == .unavailable)
        #expect(await fetcher.calls == 0)
    }

    @Test func satisfiedPathAgainFetches() async {
        let fetcher = FakeFetcher([(.success("85.12.34.201"), .zero)])
        let monitor = NetworkMonitor(reader: FakeReader(state: vpnOnly), publicIPFetcher: fetcher, debounce: .zero)

        monitor.pathChanged(satisfied: false)
        await monitor.pendingRefresh?.value
        await monitor.fetchTask?.value
        monitor.pathChanged(satisfied: true)
        await monitor.pendingRefresh?.value
        await monitor.fetchTask?.value

        #expect(monitor.connection == .vpn)
        #expect(monitor.publicIP == .available("85.12.34.201"))
    }

    @Test func reloadInterfacesUpdatesRowsWithoutFetching() async {
        let reader = SwitchableReader(onWifi)
        let fetcher = FakeFetcher([(.success("85.12.34.201"), .zero)])
        let monitor = NetworkMonitor(reader: reader, publicIPFetcher: fetcher)
        monitor.refresh()
        await monitor.fetchTask?.value

        reader.state = vpnOnly
        monitor.reloadInterfaces()
        await monitor.readTask?.value

        #expect(monitor.connection == .vpn)
        #expect(monitor.interfaces.contains { $0.bsdName == "utun4" })
        #expect(monitor.publicIP == .available("85.12.34.201"))
        #expect(await fetcher.calls == 1)
    }

    @Test func slowReadDoesNotOverwriteNewer() async {
        let reader = SlowReader(onWifi)
        reader.delay = 0.3
        let monitor = NetworkMonitor(reader: reader, publicIPFetcher: FakeFetcher([]))

        monitor.reloadInterfaces()
        let slow = monitor.readTask
        try? await Task.sleep(for: .milliseconds(50))
        reader.state = vpnOnly
        reader.delay = 0
        monitor.reloadInterfaces()
        await monitor.readTask?.value
        await slow?.value

        #expect(monitor.connection == .vpn)
    }

    @Test func storeWatchCoversAddressesPrimaryAndOpenVPN() throws {
        let matches = { (key: String) in
            DynamicStoreWatcher.patterns.contains { key.range(of: "^\($0)$", options: .regularExpression) != nil }
        }

        #expect(matches("State:/Network/Interface/utun4/IPv4"))
        #expect(matches("State:/Network/Interface/en0/IPv4"))
        #expect(matches("State:/Network/Global/IPv4"))
        #expect(matches("State:/Network/OpenVPN"))
        #expect(!matches("State:/Network/Interface/en0/IPv6"))
    }
}
