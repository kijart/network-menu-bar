public enum HardwareKind: Sendable, Equatable {
    case ethernet
    case wifi
}

public struct HardwarePort: Sendable, Equatable {
    public let bsdName: String
    public let kind: HardwareKind
    public let localizedName: String

    public init(bsdName: String, kind: HardwareKind, localizedName: String) {
        self.bsdName = bsdName
        self.kind = kind
        self.localizedName = localizedName
    }
}

public struct VPNService: Sendable, Equatable {
    public let name: String
    public let providerBundleID: String?
    /// The tunnel interface (e.g. `utun4`) while connected, otherwise `nil`.
    public let bsdName: String?

    public init(name: String, providerBundleID: String?, bsdName: String?) {
        self.name = name
        self.providerBundleID = providerBundleID
        self.bsdName = bsdName
    }
}

public enum OpenVPNClient: Sendable, Equatable {
    case tunnelblick
    case awsVPNClient
    case unknown
}

/// An OpenVPN tunnel announced through `State:/Network/OpenVPN` by Tunnelblick-style scripts.
public struct OpenVPNTunnel: Sendable, Equatable {
    public let bsdName: String
    public let client: OpenVPNClient

    public init(bsdName: String, client: OpenVPNClient) {
        self.bsdName = bsdName
        self.client = client
    }
}

public struct SystemState: Sendable, Equatable {
    /// IPv4 addresses per BSD interface name, in `getifaddrs` order.
    public var addresses: [String: [String]]
    public var hardwarePorts: [HardwarePort]
    public var vpnServices: [VPNService]
    public var primaryInterface: String?
    /// The interface the kernel routes a public address through.
    public var routeInterface: String?
    public var openVPNTunnel: OpenVPNTunnel?
    public var wifiSSID: String?

    public init(
        addresses: [String: [String]] = [:],
        hardwarePorts: [HardwarePort] = [],
        vpnServices: [VPNService] = [],
        primaryInterface: String? = nil,
        routeInterface: String? = nil,
        openVPNTunnel: OpenVPNTunnel? = nil,
        wifiSSID: String? = nil
    ) {
        self.addresses = addresses
        self.hardwarePorts = hardwarePorts
        self.vpnServices = vpnServices
        self.primaryInterface = primaryInterface
        self.routeInterface = routeInterface
        self.openVPNTunnel = openVPNTunnel
        self.wifiSSID = wifiSSID
    }
}

public protocol SystemStateReading: Sendable {
    func read() -> SystemState
}
