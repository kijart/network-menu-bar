public enum InterfaceKind: Sendable, Equatable {
    case ethernet
    case wifi
    case vpn
}

public enum VPNProvider: Sendable, Equatable {
    case wireGuard
    case openVPN
    case awsVPN
}

public struct NetworkInterfaceInfo: Identifiable, Sendable, Equatable {
    public var id: String { bsdName }
    public let bsdName: String
    public let kind: InterfaceKind
    /// The VPN tunnel name, or the hardware port's localized name.
    public let name: String?
    public let vpnProvider: VPNProvider?
    public let ssid: String?
    public let ipv4: String?

    public var isActive: Bool { ipv4 != nil }

    public init(
        bsdName: String,
        kind: InterfaceKind,
        name: String? = nil,
        vpnProvider: VPNProvider? = nil,
        ssid: String? = nil,
        ipv4: String? = nil
    ) {
        self.bsdName = bsdName
        self.kind = kind
        self.name = name
        self.vpnProvider = vpnProvider
        self.ssid = ssid
        self.ipv4 = ipv4
    }
}
