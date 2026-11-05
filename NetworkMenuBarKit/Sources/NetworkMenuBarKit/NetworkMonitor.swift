import Foundation
import Network
import Observation

@MainActor
@Observable
public final class NetworkMonitor {
    public private(set) var interfaces: [NetworkInterfaceInfo] = []
    public private(set) var primaryInterface: String?
    public private(set) var connection: ConnectionKind = .offline
    public private(set) var publicIP: PublicIPState = .loading(previous: nil)

    public var viaInterface: NetworkInterfaceInfo? {
        NetworkMenuBarKit.viaInterface(interfaces: interfaces, primaryInterface: primaryInterface)
    }

    @ObservationIgnored private let reader: any SystemStateReading
    @ObservationIgnored private let publicIPFetcher: any PublicIPFetching
    @ObservationIgnored private let debounce: Duration
    @ObservationIgnored private var pathMonitor: NWPathMonitor?
    @ObservationIgnored private var pathSatisfied = true
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
        updateInterfaces()
        let monitor = NWPathMonitor()
        monitor.pathUpdateHandler = { [weak self] path in
            let satisfied = path.status == .satisfied
            Task { @MainActor in self?.pathChanged(satisfied: satisfied) }
        }
        monitor.start(queue: DispatchQueue(label: "NetworkMonitor.path"))
        pathMonitor = monitor
    }

    /// Re-reads the interfaces now and re-fetches the public IP, superseding any fetch in flight.
    public func refresh() {
        updateInterfaces()

        fetchTask?.cancel()
        guard connection != .offline else {
            fetchTask = nil
            publicIP = .unavailable
            return
        }

        publicIP = .loading(previous: publicIP.address)
        fetchTask = Task { [weak self, publicIPFetcher] in
            let result: PublicIPState
            do {
                result = .available(try await publicIPFetcher.fetchPublicIP())
            } catch {
                result = .unavailable
            }
            guard !Task.isCancelled else { return }
            self?.publicIP = result
        }
    }

    private func updateInterfaces() {
        let state = reader.read()
        interfaces = classify(state)
        primaryInterface = state.primaryInterface
        connection = pathSatisfied ? connectionKind(interfaces: interfaces, primaryInterface: primaryInterface) : .offline
    }

    /// A tunnel such as WireGuard keeps its address after Wi-Fi or Ethernet drop,
    /// so only the system's path status can tell that nothing is reachable.
    func pathChanged(satisfied: Bool) {
        pathSatisfied = satisfied
        scheduleRefresh()
    }

    /// Coalesces bursts of path updates (e.g. a VPN connecting) into one refresh.
    func scheduleRefresh() {
        pendingRefresh?.cancel()
        pendingRefresh = Task { [weak self, debounce] in
            try? await Task.sleep(for: debounce)
            guard !Task.isCancelled else { return }
            self?.refresh()
        }
    }
}
