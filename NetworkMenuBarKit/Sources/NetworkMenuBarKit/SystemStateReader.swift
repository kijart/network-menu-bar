import CoreWLAN
import Darwin
import Foundation
import SystemConfiguration

public struct SystemStateReader: SystemStateReading {
    public init() {}

    public func read() -> SystemState {
        let store = SCDynamicStoreCreate(nil, "NetworkMenuBar" as CFString, nil, nil)
        let addresses = Self.ipv4Addresses()
        return SystemState(
            addresses: addresses,
            hardwarePorts: Self.hardwarePorts(),
            vpnServices: store.map(Self.vpnServices) ?? [],
            primaryInterface: store.flatMap(Self.primaryInterface),
            routeInterface: Self.routeInterface(addresses: addresses),
            openVPNTunnel: store.flatMap(Self.openVPNTunnel),
            wifiSSID: CWWiFiClient.shared().interface()?.ssid()
        )
    }

    static func ipv4Addresses() -> [String: [String]] {
        var head: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&head) == 0, let first = head else { return [:] }
        defer { freeifaddrs(head) }

        var result: [String: [String]] = [:]
        for pointer in sequence(first: first, next: { $0.pointee.ifa_next }) {
            let entry = pointer.pointee
            guard let address = entry.ifa_addr, address.pointee.sa_family == UInt8(AF_INET) else { continue }

            let sin = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
            guard let ip = string(from: sin.sin_addr) else { continue }
            result[String(cString: entry.ifa_name), default: []].append(ip)
        }
        return result
    }

    static func string(from address: in_addr) -> String? {
        var address = address
        var host = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
        guard inet_ntop(AF_INET, &address, &host, socklen_t(INET_ADDRSTRLEN)) != nil else { return nil }
        return String(decoding: host.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
    }

    /// Connecting a UDP socket sends nothing but makes the kernel pick the source address
    /// from the routing table, which identifies the interface.
    static func routeInterface(addresses: [String: [String]]) -> String? {
        let fd = socket(AF_INET, SOCK_DGRAM, IPPROTO_UDP)
        guard fd >= 0 else { return nil }
        defer { close(fd) }

        var remote = sockaddr_in()
        remote.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        remote.sin_family = sa_family_t(AF_INET)
        remote.sin_port = in_port_t(443).bigEndian
        remote.sin_addr.s_addr = inet_addr("1.1.1.1")
        var local = sockaddr_in()
        var length = socklen_t(MemoryLayout<sockaddr_in>.size)
        let connected = withUnsafePointer(to: &remote) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { connect(fd, $0, length) == 0 }
        }
        guard connected, withUnsafeMutablePointer(to: &local, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) { getsockname(fd, $0, &length) == 0 }
        }), let source = string(from: local.sin_addr) else { return nil }
        return addresses.first { $0.value.contains(source) }?.key
    }

    static func hardwarePorts() -> [HardwarePort] {
        guard let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else { return [] }
        let bridgeMembers = bridgeMemberNames()
        return interfaces.compactMap { interface in
            guard let bsdName = SCNetworkInterfaceGetBSDName(interface) as String?,
                  let type = SCNetworkInterfaceGetInterfaceType(interface) else { return nil }
            let kind: HardwareKind
            switch type {
            case kSCNetworkInterfaceTypeEthernet: kind = .ethernet
            case kSCNetworkInterfaceTypeIEEE80211: kind = .wifi
            default: return nil
            }
            let name = SCNetworkInterfaceGetLocalizedDisplayName(interface) as String? ?? bsdName
            return HardwarePort(bsdName: bsdName, kind: kind, localizedName: name, isBridgeMember: bridgeMembers.contains(bsdName))
        }
    }

    /// Bridge APIs are private, so the members are read from the network preferences.
    static func bridgeMemberNames() -> Set<String> {
        guard let preferences = SCPreferencesCreate(nil, "NetworkMenuBar" as CFString, nil),
              let virtual = SCPreferencesGetValue(preferences, "VirtualNetworkInterfaces" as CFString) as? [String: Any],
              let bridges = virtual["Bridge"] as? [String: [String: Any]] else { return [] }
        return Set(bridges.values.flatMap { $0["Interfaces"] as? [String] ?? [] })
    }

    static func vpnServices(store: SCDynamicStore) -> [VPNService] {
        let pattern = "Setup:/Network/Service/[^/]+/Interface" as CFString
        guard let keys = SCDynamicStoreCopyKeyList(store, pattern) as? [String] else { return [] }

        return keys.compactMap { key in
            guard let interface = SCDynamicStoreCopyValue(store, key as CFString) as? [String: Any],
                  interface["Type"] as? String == "VPN" else { return nil }
            let serviceID = String(key.split(separator: "/")[3])
            let setup = SCDynamicStoreCopyValue(store, "Setup:/Network/Service/\(serviceID)" as CFString) as? [String: Any]
            return VPNService(
                name: setup?["UserDefinedName"] as? String ?? serviceID,
                providerBundleID: interface["SubType"] as? String,
                bsdName: connectedInterface(serviceID: serviceID)
            )
        }
        .sorted { $0.name < $1.name }
    }

    /// Network Extension VPNs publish their state under a session service ID that differs
    /// from the setup one, so the tunnel interface is read through `SCNetworkConnection`.
    static func connectedInterface(serviceID: String) -> String? {
        guard let connection = SCNetworkConnectionCreateWithServiceID(nil, serviceID as CFString, nil, nil),
              SCNetworkConnectionGetStatus(connection) == .connected,
              let status = SCNetworkConnectionCopyExtendedStatus(connection) as? [String: Any],
              let ipv4 = status["IPv4"] as? [String: Any] else { return nil }
        return ipv4["InterfaceName"] as? String
    }

    static func primaryInterface(store: SCDynamicStore) -> String? {
        let global = SCDynamicStoreCopyValue(store, "State:/Network/Global/IPv4" as CFString) as? [String: Any]
        return global?["PrimaryInterface"] as? String
    }

    static func openVPNTunnel(store: SCDynamicStore) -> OpenVPNTunnel? {
        let info = SCDynamicStoreCopyValue(store, "State:/Network/OpenVPN" as CFString) as? [String: Any]
        return info.flatMap { openVPNTunnel(info: $0, processName: processName) }
    }

    /// The key can outlive its client (e.g. after a crash), so a tunnel whose process is gone is ignored.
    static func openVPNTunnel(info: [String: Any], processName: (Int32) -> String?) -> OpenVPNTunnel? {
        guard let bsdName = info["TunnelDevice"] as? String else { return nil }
        guard let pid = (info["PID"] as? NSNumber)?.int32Value else {
            return OpenVPNTunnel(bsdName: bsdName, client: .unknown)
        }
        guard let owner = processName(pid) else { return nil }
        let client: OpenVPNClient = switch owner {
        case "openvpn": .tunnelblick
        case let name where name.hasPrefix("aws-client-vpn"): .awsVPNClient
        default: .unknown
        }
        return OpenVPNTunnel(bsdName: bsdName, client: client)
    }

    /// The kernel's short command name (truncated to 16 characters).
    static func processName(pid: Int32) -> String? {
        var mib: [Int32] = [CTL_KERN, KERN_PROC, KERN_PROC_PID, pid]
        var info = kinfo_proc()
        var size = MemoryLayout<kinfo_proc>.stride
        guard sysctl(&mib, u_int(mib.count), &info, &size, nil, 0) == 0, size > 0 else { return nil }
        return withUnsafeBytes(of: info.kp_proc.p_comm) { buffer in
            String(decoding: buffer.prefix { $0 != 0 }, as: UTF8.self)
        }
    }
}
