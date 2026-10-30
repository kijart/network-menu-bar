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

/// The connection the menu bar icon represents: any connected VPN first, then the primary interface.
public func activeInterface(interfaces: [NetworkInterfaceInfo], primaryInterface: String?) -> NetworkInterfaceInfo? {
    let active = interfaces.filter(\.isActive)
    let vpns = active.filter { $0.kind == .vpn }
    return vpns.first { $0.bsdName == primaryInterface }
        ?? vpns.first
        ?? active.first { $0.bsdName == primaryInterface }
        ?? active.first
}

/// The interface holding the default route, i.e. where public traffic exits.
public func viaInterface(interfaces: [NetworkInterfaceInfo], primaryInterface: String?) -> NetworkInterfaceInfo? {
    let active = interfaces.filter(\.isActive)
    return active.first { $0.bsdName == primaryInterface } ?? active.first
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
