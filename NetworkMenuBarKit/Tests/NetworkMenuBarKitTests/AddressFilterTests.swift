import Testing
@testable import NetworkMenuBarKit

@Test(arguments: ["192.168.1.34", "10.8.0.2", "172.16.0.1"])
func acceptsPrivateAddresses(_ ip: String) {
    #expect(isUsablePrivateIPv4(ip))
}

@Test(arguments: ["127.0.0.1", "169.254.12.3", "", "not-an-ip", "300.1.1.1"])
func rejectsUnusableAddresses(_ ip: String) {
    #expect(!isUsablePrivateIPv4(ip))
}
