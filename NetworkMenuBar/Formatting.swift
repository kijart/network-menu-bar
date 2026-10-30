import NetworkMenuBarKit

extension ConnectionKind {
    var symbolName: String {
        switch self {
        case .ethernet: "cable.connector"
        case .wifi: "wifi"
        case .vpn: "lock.shield"
        case .offline: "wifi.slash"
        }
    }
}

extension VPNProvider {
    var displayName: String {
        switch self {
        case .wireGuard: "WireGuard"
        case .openVPN: "OpenVPN"
        case .awsVPN: "AWS VPN"
        }
    }
}

extension NetworkInterfaceInfo {
    var title: String {
        switch kind {
        case .ethernet: String(localized: "Ethernet")
        case .wifi: String(localized: "Wi-Fi")
        case .vpn: name ?? vpnProvider?.displayName ?? String(localized: "VPN")
        }
    }

    /// Secondary line for the detailed layout, e.g. "en0 · Home" or "utun4 · WireGuard".
    var detail: String {
        guard isActive else { return String(localized: "Not connected") }
        let extra: String? = switch kind {
        case .ethernet: name
        case .wifi: ssid
        case .vpn: name == nil ? nil : vpnProvider?.displayName
        }
        return [bsdName, extra].compactMap { $0 }.joined(separator: " · ")
    }
}
