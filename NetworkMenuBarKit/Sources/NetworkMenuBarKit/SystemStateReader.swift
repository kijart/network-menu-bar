import CoreWLAN
import Darwin
import Foundation
import SystemConfiguration

public struct SystemStateReader: SystemStateReading {
    public init() {}

    public func read() -> SystemState {
        let store = SCDynamicStoreCreate(nil, "NetworkMenuBar" as CFString, nil, nil)
        return SystemState(
            addresses: Self.ipv4Addresses(),
            hardwarePorts: Self.hardwarePorts(),
            vpnServices: store.map(Self.vpnServices) ?? [],
            primaryInterface: store.flatMap(Self.primaryInterface),
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

            var host = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
            let ok = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { sin in
                var addr = sin.pointee.sin_addr
                return inet_ntop(AF_INET, &addr, &host, socklen_t(INET_ADDRSTRLEN)) != nil
            }
            guard ok else { continue }
            let ip = String(decoding: host.prefix { $0 != 0 }.map { UInt8(bitPattern: $0) }, as: UTF8.self)
            result[String(cString: entry.ifa_name), default: []].append(ip)
        }
        return result
    }

    static func hardwarePorts() -> [HardwarePort] {
        guard let interfaces = SCNetworkInterfaceCopyAll() as? [SCNetworkInterface] else { return [] }
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
            return HardwarePort(bsdName: bsdName, kind: kind, localizedName: name)
        }
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
        guard let info = SCDynamicStoreCopyValue(store, "State:/Network/OpenVPN" as CFString) as? [String: Any],
              let bsdName = info["TunnelDevice"] as? String else { return nil }
        let owner = (info["PID"] as? Int32).flatMap(processName) ?? ""
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
