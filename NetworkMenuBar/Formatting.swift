import NetworkMenuBarKit

extension ConnectionKind {
    var title: String {
        switch self {
        case .ethernet: String(localized: "Ethernet")
        case .wifi: String(localized: "Wi-Fi")
        case .vpn: String(localized: "VPN")
        case .offline: String(localized: "Offline")
        }
    }
}

extension InterfaceKind {
    var symbolName: String {
        switch self {
        case .ethernet: "cable.connector"
        case .wifi: "wifi"
        case .vpn: "lock.shield"
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
        case .vpn: name ?? vpnProvider?.displayName ?? String(localized: "VPN (\(bsdName))")
        }
    }

    /// Appends the BSD name when another row has the same title, e.g. two active Ethernet ports.
    func title(among interfaces: [NetworkInterfaceInfo]) -> String {
        let isAmbiguous = interfaces.contains { $0.id != id && $0.title == title }
        return isAmbiguous ? "\(title) (\(bsdName))" : title
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
