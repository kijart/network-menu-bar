import Foundation
import Testing
@testable import NetworkMenuBarKit

private func tunnel(pid: Int32? = 4242, owner: String?) -> OpenVPNTunnel? {
    var info: [String: Any] = ["TunnelDevice": "utun5"]
    info["PID"] = pid.map { NSNumber(value: $0) }
    return SystemStateReader.openVPNTunnel(info: info) { $0 == pid ? owner : nil }
}

@Test func tunnelblickOwnsTheTunnel() {
    #expect(tunnel(owner: "openvpn") == OpenVPNTunnel(bsdName: "utun5", client: .tunnelblick))
}

@Test func awsVPNClientOwnsTheTunnel() {
    #expect(tunnel(owner: "aws-client-vpn-d") == OpenVPNTunnel(bsdName: "utun5", client: .awsVPNClient))
}

@Test func otherOwnerIsAnUnknownClient() {
    #expect(tunnel(owner: "viscosity") == OpenVPNTunnel(bsdName: "utun5", client: .unknown))
}

@Test func keyWithoutPIDIsAnUnknownClient() {
    #expect(tunnel(pid: nil, owner: nil) == OpenVPNTunnel(bsdName: "utun5", client: .unknown))
}

@Test func keyLeftByADeadProcessIsIgnored() {
    #expect(tunnel(owner: nil) == nil)
}

@Test func keyWithoutTunnelDeviceIsIgnored() {
    #expect(SystemStateReader.openVPNTunnel(info: ["PID": NSNumber(value: 1)]) { _ in "openvpn" } == nil)
}
