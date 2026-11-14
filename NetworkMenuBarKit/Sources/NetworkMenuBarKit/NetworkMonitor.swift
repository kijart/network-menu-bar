import Foundation
import Network
import Observation

@MainActor
@Observable
public final class NetworkMonitor {
    public private(set) var interfaces: [NetworkInterfaceInfo] = []
    public private(set) var primaryInterface: String?
    public private(set) var routeInterface: String?
    public private(set) var connection: ConnectionKind = .offline
    public private(set) var publicIP: PublicIPState = .loading(previous: nil)

    public var viaInterface: NetworkInterfaceInfo? {
        NetworkMenuBarKit.viaInterface(interfaces: interfaces, primaryInterface: primaryInterface, routeInterface: routeInterface)
    }

    @ObservationIgnored private let reader: any SystemStateReading
    @ObservationIgnored private let publicIPFetcher: any PublicIPFetching
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private var pathMonitor: NWPathMonitor?
    @ObservationIgnored private var storeWatcher: DynamicStoreWatcher?
    @ObservationIgnored private var pathSatisfied = true
    @ObservationIgnored private var session = 0
    @ObservationIgnored private var router: String?
    /// What the latest public IP lookup was made for; nil after a failure, so the next change retries.
    @ObservationIgnored private var lookupKey: LookupKey?
    @ObservationIgnored private var readsStarted = 0
    @ObservationIgnored private var readsApplied = 0
    @ObservationIgnored private(set) var readTask: Task<Void, Never>?
    @ObservationIgnored private(set) var pendingRefresh: Task<Void, Never>?
    @ObservationIgnored private(set) var fetchTask: Task<Void, Never>?

    public init(
        reader: any SystemStateReading = SystemStateReader(),
        publicIPFetcher: any PublicIPFetching = PublicIPService(),
        debounce: Duration = .milliseconds(500)
    ) {
        self.reader = reader
        self.publicIPFetcher = publicIPFetcher
        self.debounce = debounce
    }

    /// Shows the current interfaces right away and starts watching for network changes.
    /// The monitor's initial path update triggers the first public IP fetch.
    public func start() {
        guard pathMonitor == nil else { return }
        session += 1
        let session = session
        reloadInterfaces()
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let satisfied = path.status == .satisfied
            Task { @MainActor in
                guard let self, self.session == session else { return }
                self.pathChanged(satisfied: satisfied)
            }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor.path"))
        pathMonitor = monitor

        let watcher = DynamicStoreWatcher { [weak self] in
            Task { @MainActor in
                guard let self, self.session == session else { return }
                self.scheduleRefresh()
            }
        }
        watcher.start()
        storeWatcher = watcher
    }

    /// Stops watching for network changes and cancels any pending refresh, read or fetch.
    /// The last published values stay; `start()` can be called again.
    public func stop() {
        session += 1
        pathMonitor?.cancel()
        pathMonitor = nil
        storeWatcher = nil
        pendingRefresh?.cancel()
        readTask?.cancel()
        fetchTask?.cancel()
    }

    /// Re-reads the interfaces without touching the public IP, e.g. when the menu opens.
    public func reloadInterfaces() {
        readTask = Task { [weak self] in await self?.updateInterfaces() }
    }

    /// Re-reads the interfaces now and re-fetches the public IP, superseding any fetch in flight.
    public func refresh() {
        fetchTask?.cancel()
        publicIP = .loading(previous: publicIP.address)
        fetchTask = Task { [weak self] in
            await self?.updateInterfaces()
            await self?.lookUpPublicIP()
        }
    }

    /// The parts of the state that can change the public IP. A VPN connecting changes several
    /// store keys a second or more apart; only the ones that change this trigger a new lookup.
    private struct LookupKey: Equatable {
        var connection: ConnectionKind
        var viaInterface: String?
        var viaAddress: String?
        var primaryInterface: String?
        var router: String?
    }

    private var currentLookupKey: LookupKey {
        LookupKey(
            connection: connection,
            viaInterface: viaInterface?.bsdName,
            viaAddress: viaInterface?.ipv4,
            primaryInterface: primaryInterface,
            router: router
        )
    }

    private func lookUpPublicIP() async {
        guard !Task.isCancelled else { return }
        let key = currentLookupKey
        lookupKey = key
        guard connection != .offline else {
            publicIP = .unavailable
            return
        }

        let result: PublicIPState
        do {
            result = .available(try await publicIPFetcher.fetchPublicIP())
        } catch {
            result = .unavailable
        }
        guard !Task.isCancelled else { return }
        publicIP = result
        if case .unavailable = result, lookupKey == key { lookupKey = nil }
    }

    /// Reads off the main actor, since the reader makes several synchronous IPC calls.
    /// A read that finishes after a newer one has been applied, or after a cancellation, is dropped.
    private func updateInterfaces() async {
        readsStarted += 1
        let read = readsStarted
        let state = await Task.detached { [reader] in reader.read() }.value
        guard !Task.isCancelled, read > readsApplied else { return }
        readsApplied = read
        interfaces = classify(state)
        primaryInterface = state.primaryInterface
        routeInterface = state.routeInterface
        router = state.router
        connection = pathSatisfied ? connectionKind(interfaces: interfaces, primaryInterface: primaryInterface) : .offline
    }

    /// A tunnel such as WireGuard keeps its address after Wi-Fi or Ethernet drop,
    /// so only the system's path status can tell that nothing is reachable.
    func pathChanged(satisfied: Bool) {
        pathSatisfied = satisfied
        scheduleRefresh()
    }

    /// Coalesces bursts of path updates (e.g. a VPN connecting) into one refresh, which looks up
    /// the public IP again only when something that can change it has changed.
    func scheduleRefresh() {
        pendingRefresh?.cancel()
        pendingRefresh = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            await self?.updateInterfaces()
            guard !Task.isCancelled, let self, self.currentLookupKey != self.lookupKey else { return }
            self.fetchTask?.cancel()
            self.publicIP = .loading(previous: self.publicIP.address)
            self.fetchTask = Task { [weak self] in await self?.lookUpPublicIP() }
        }
    }
}
