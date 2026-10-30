import Testing
@testable import NetworkMenuBarKit

private let wifi = HardwarePort(bsdName: "en0", kind: .wifi, localizedName: "Wi-Fi")
private let usbEthernet = HardwarePort(bsdName: "en7", kind: .ethernet, localizedName: "USB 10/100/1000 LAN")
private let thunderbolt = HardwarePort(bsdName: "en1", kind: .ethernet, localizedName: "Thunderbolt 1")

private func vpnRows(_ state: SystemState) -> [NetworkInterfaceInfo] {
    classify(state).filter { $0.kind == .vpn }
}

@Test func wifiWaitingForDHCPIsInactive() throws {
    let state = SystemState(addresses: ["en0": ["169.254.5.5"]], hardwarePorts: [wifi], wifiSSID: "Home")

    let row = try #require(classify(state).first { $0.kind == .wifi })
    #expect(row.ipv4 == nil)
    #expect(row.ssid == nil)
    #expect(!row.isActive)
}

@Test func activeWifiCarriesSSID() throws {
    let state = SystemState(addresses: ["en0": ["192.168.1.34"]], hardwarePorts: [wifi], wifiSSID: "Home")

    let row = try #require(classify(state).first { $0.kind == .wifi })
    #expect(row.ipv4 == "192.168.1.34")
    #expect(row.ssid == "Home")
}

@Test func firstUsableAliasWins() throws {
    let state = SystemState(
        addresses: ["en7": ["169.254.1.1", "192.168.1.20", "192.168.1.21"]],
        hardwarePorts: [usbEthernet]
    )

    let row = try #require(classify(state).first { $0.kind == .ethernet })
    #expect(row.ipv4 == "192.168.1.20")
}

@Test func unpluggedEthernetCollapsesToOneRow() {
    let state = SystemState(hardwarePorts: [usbEthernet, thunderbolt])

    let rows = classify(state).filter { $0.kind == .ethernet }
    #expect(rows.count == 1)
    #expect(rows.first?.bsdName == "en7")
    #expect(rows.first?.isActive == false)
}

@Test func onlyActiveEthernetPortsAreListedWhenAnyIsUp() {
    let state = SystemState(addresses: ["en1": ["10.0.0.5"]], hardwarePorts: [usbEthernet, thunderbolt])

    let rows = classify(state).filter { $0.kind == .ethernet }
    #expect(rows.map(\.bsdName) == ["en1"])
    #expect(rows.first?.name == "Thunderbolt 1")
}

@Test func wireGuardTunnelUsesServiceName() throws {
    let state = SystemState(
        addresses: ["utun4": ["10.8.0.2"]],
        vpnServices: [VPNService(name: "HAL 9000", providerBundleID: "com.wireguard.macos", bsdName: "utun4")]
    )

    let row = try #require(vpnRows(state).first)
    #expect(row.bsdName == "utun4")
    #expect(row.name == "HAL 9000")
    #expect(row.vpnProvider == .wireGuard)
    #expect(row.ipv4 == "10.8.0.2")
}

@Test func disconnectedVPNIsNotListed() {
    let state = SystemState(
        vpnServices: [VPNService(name: "SkynetMAD", providerBundleID: "com.wireguard.macos", bsdName: nil)]
    )

    #expect(vpnRows(state).isEmpty)
}

@Test func utunWithoutIPv4IsIgnored() {
    let state = SystemState(addresses: ["en0": ["192.168.1.34"]], hardwarePorts: [wifi])

    #expect(vpnRows(state).isEmpty)
}

@Test(arguments: [
    (OpenVPNClient.awsVPNClient, VPNProvider.awsVPN),
    (.tunnelblick, .openVPN),
    (.unknown, .openVPN),
])
func openVPNTunnelUsesClient(client: OpenVPNClient, provider: VPNProvider) throws {
    let state = SystemState(
        addresses: ["utun6": ["10.9.0.6"]],
        openVPNTunnel: OpenVPNTunnel(bsdName: "utun6", client: client)
    )

    let row = try #require(vpnRows(state).first)
    #expect(row.vpnProvider == provider)
    #expect(row.name == nil)
}

@Test func staleOpenVPNTunnelIsIgnored() {
    let state = SystemState(openVPNTunnel: OpenVPNTunnel(bsdName: "utun6", client: .tunnelblick))

    #expect(vpnRows(state).isEmpty)
}

@Test func unknownTunnelHasNoProvider() throws {
    let state = SystemState(addresses: ["utun7": ["10.7.0.7"]])

    let row = try #require(vpnRows(state).first)
    #expect(row.vpnProvider == nil)
    #expect(row.name == nil)
}

@Test func rowOrderIsEthernetWifiVPN() {
    let state = SystemState(
        addresses: [
            "utun5": ["10.20.200.5"],
            "utun4": ["172.25.200.2"],
            "en0": ["10.10.10.14"],
            "en7": ["10.10.10.15"],
        ],
        hardwarePorts: [wifi, usbEthernet],
        vpnServices: [VPNService(name: "HAL 9000", providerBundleID: "com.wireguard.macos", bsdName: "utun5")],
        openVPNTunnel: OpenVPNTunnel(bsdName: "utun4", client: .awsVPNClient)
    )

    #expect(classify(state).map(\.bsdName) == ["en7", "en0", "utun4", "utun5"])
}
