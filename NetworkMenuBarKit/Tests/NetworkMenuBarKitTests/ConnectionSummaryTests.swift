import Testing
@testable import NetworkMenuBarKit

private let ethernet = NetworkInterfaceInfo(bsdName: "en9", kind: .ethernet, ipv4: "10.10.10.15")
private let wifi = NetworkInterfaceInfo(bsdName: "en0", kind: .wifi, ipv4: "10.10.10.14")
private let inactiveEthernet = NetworkInterfaceInfo(bsdName: "en9", kind: .ethernet)
private let wireGuard = NetworkInterfaceInfo(bsdName: "utun5", kind: .vpn, name: "HAL 9000", vpnProvider: .wireGuard, ipv4: "10.20.200.5")
private let aws = NetworkInterfaceInfo(bsdName: "utun4", kind: .vpn, vpnProvider: .awsVPN, ipv4: "172.25.200.2")

@Test func vpnWinsOverPrimaryEthernet() {
    #expect(connectionKind(interfaces: [ethernet, aws], primaryInterface: "en9") == .vpn)
}

@Test func primaryWifiWhenNoVPN() {
    #expect(connectionKind(interfaces: [inactiveEthernet, wifi], primaryInterface: "en0") == .wifi)
}

@Test func firstActiveWhenPrimaryIsUnknown() {
    #expect(connectionKind(interfaces: [inactiveEthernet, wifi], primaryInterface: nil) == .wifi)
}

@Test func offlineWhenNothingActive() {
    let interfaces = [inactiveEthernet, NetworkInterfaceInfo(bsdName: "en0", kind: .wifi)]

    #expect(connectionKind(interfaces: interfaces, primaryInterface: nil) == .offline)
    #expect(activeInterface(interfaces: interfaces, primaryInterface: nil) == nil)
    #expect(viaInterface(interfaces: interfaces, primaryInterface: nil) == nil)
}

@Test func activeInterfacePrefersPrimaryVPN() {
    let interfaces = [ethernet, aws, wireGuard]

    #expect(activeInterface(interfaces: interfaces, primaryInterface: "utun5") == wireGuard)
    #expect(activeInterface(interfaces: interfaces, primaryInterface: "en9") == aws)
}

@Test func viaFollowsPrimaryWithSplitTunnel() {
    #expect(viaInterface(interfaces: [ethernet, aws], primaryInterface: "en9") == ethernet)
}

@Test func viaIsVPNWhenItHoldsDefaultRoute() {
    #expect(viaInterface(interfaces: [ethernet, wireGuard], primaryInterface: "utun5") == wireGuard)
}

@Test func privateTextUsesActiveInterface() {
    let text = menuBarText(
        source: .privateIP,
        interfaces: [wifi, wireGuard],
        primaryInterface: "utun5",
        publicIP: .available("85.12.34.201")
    )

    #expect(text == "10.20.200.5")
}

@Test func publicTextWhileLoadingShowsPrevious() {
    let text = menuBarText(source: .publicIP, interfaces: [wifi], primaryInterface: "en0", publicIP: .loading(previous: "85.12.34.201"))

    #expect(text == "85.12.34.201")
}

@Test func publicTextUnavailableIsNil() {
    #expect(menuBarText(source: .publicIP, interfaces: [wifi], primaryInterface: "en0", publicIP: .unavailable) == nil)
}

@Test func publicIPStateAddress() {
    #expect(PublicIPState.available("1.2.3.4").address == "1.2.3.4")
    #expect(PublicIPState.loading(previous: "1.2.3.4").address == "1.2.3.4")
    #expect(PublicIPState.loading(previous: nil).address == nil)
    #expect(PublicIPState.unavailable.address == nil)
}
