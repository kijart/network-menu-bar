public enum ConnectionKind: Sendable, Equatable {
    case ethernet
    case wifi
    case vpn
    case offline
}

public enum MenuBarTextSource: String, Sendable, CaseIterable {
    case publicIP
    case privateIP
}

/// The connection the app treats as current: any connected VPN first, then the primary interface.
public func activeInterface(interfaces: [NetworkInterfaceInfo], primaryInterface: String?) -> NetworkInterfaceInfo? {
    let active = interfaces.filter(\.isActive)
    let vpns = active.filter { $0.kind == .vpn }
    return vpns.first { $0.bsdName == primaryInterface }
        ?? vpns.first
        ?? active.first { $0.bsdName == primaryInterface }
        ?? active.first
}

/// Where public traffic exits. Full-tunnel VPNs such as WireGuard add `0/1` and `128/1` routes
/// instead of replacing the default route, so the primary interface stays on the physical port.
public func viaInterface(
    interfaces: [NetworkInterfaceInfo],
    primaryInterface: String?,
    routeInterface: String?
) -> NetworkInterfaceInfo? {
    let active = interfaces.filter(\.isActive)
    return active.first { $0.bsdName == routeInterface }
        ?? active.first { $0.bsdName == primaryInterface }
        ?? active.first
}

public func connectionKind(interfaces: [NetworkInterfaceInfo], primaryInterface: String?) -> ConnectionKind {
    switch activeInterface(interfaces: interfaces, primaryInterface: primaryInterface)?.kind {
    case .ethernet: .ethernet
    case .wifi: .wifi
    case .vpn: .vpn
    case nil: .offline
    }
}

public func menuBarText(
    source: MenuBarTextSource,
    interfaces: [NetworkInterfaceInfo],
    primaryInterface: String?,
    publicIP: PublicIPState
) -> String? {
    switch source {
    case .publicIP: publicIP.address
    case .privateIP: activeInterface(interfaces: interfaces, primaryInterface: primaryInterface)?.ipv4
    }
}
