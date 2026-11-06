/// Turns raw system state into menu rows: Ethernet, then Wi-Fi, then connected VPNs.
public func classify(_ state: SystemState) -> [NetworkInterfaceInfo] {
    ethernetRows(state) + wifiRows(state) + vpnRows(state)
}

private func usableIPv4(_ bsdName: String, in state: SystemState) -> String? {
    state.addresses[bsdName]?.first(where: isUsablePrivateIPv4)
}

private func ethernetRows(_ state: SystemState) -> [NetworkInterfaceInfo] {
    let ports = state.hardwarePorts.filter { $0.kind == .ethernet }
    let rows = ports.map { port in
        NetworkInterfaceInfo(
            bsdName: port.bsdName,
            kind: .ethernet,
            name: port.localizedName,
            ipv4: usableIPv4(port.bsdName, in: state)
        )
    }
    let active = rows.filter(\.isActive)
    return active.isEmpty ? Array(rows.prefix(1)) : active
}

private func wifiRows(_ state: SystemState) -> [NetworkInterfaceInfo] {
    state.hardwarePorts.filter { $0.kind == .wifi }.map { port in
        let ipv4 = usableIPv4(port.bsdName, in: state)
        return NetworkInterfaceInfo(
            bsdName: port.bsdName,
            kind: .wifi,
            name: port.localizedName,
            ssid: ipv4 == nil ? nil : state.wifiSSID,
            ipv4: ipv4
        )
    }
}

private func vpnRows(_ state: SystemState) -> [NetworkInterfaceInfo] {
    state.addresses.keys
        .filter { $0.hasPrefix("utun") }
        .sorted()
        .compactMap { bsdName in
            guard let ipv4 = usableIPv4(bsdName, in: state) else { return nil }
            if let service = state.vpnServices.first(where: { $0.bsdName == bsdName }) {
                let provider: VPNProvider? = switch service.providerBundleID {
                case "com.wireguard.macos": .wireGuard
                case "org.openvpn.client.app": .openVPN
                default: nil
                }
                return NetworkInterfaceInfo(bsdName: bsdName, kind: .vpn, name: service.name, vpnProvider: provider, ipv4: ipv4)
            }
            if let tunnel = state.openVPNTunnel, tunnel.bsdName == bsdName {
                let provider: VPNProvider = tunnel.client == .awsVPNClient ? .awsVPN : .openVPN
                return NetworkInterfaceInfo(bsdName: bsdName, kind: .vpn, vpnProvider: provider, ipv4: ipv4)
            }
            return NetworkInterfaceInfo(bsdName: bsdName, kind: .vpn, ipv4: ipv4)
        }
}
