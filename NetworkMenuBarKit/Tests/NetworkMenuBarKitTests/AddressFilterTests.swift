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

@Test(arguments: ["85.12.34.201", "8.8.8.8", "1.0.0.1", "223.255.255.254", "100.63.255.255", "172.32.0.1"])
func acceptsPublicAddresses(_ ip: String) {
    #expect(isPublicIPv4(ip))
}

@Test(arguments: [
    "1.2.3", "127.1", "1.2.3.4.5", "0x7f.0.0.1", "01.02.03.04", "1.2.3.04", "1.2.3.4%en0",
    "1.2.3.256", "+1.2.3.4", "1.2.3.4 ", "١.٢.٣.٤", "", "1..2.3",
])
func rejectsMalformedPublicAddresses(_ ip: String) {
    #expect(!isPublicIPv4(ip))
}

@Test(arguments: [
    "0.0.0.0", "0.1.2.3", "10.0.0.1", "100.64.0.1", "100.127.255.255", "127.0.0.1", "169.254.1.1",
    "172.16.0.1", "172.31.255.255", "192.168.1.1", "224.0.0.1", "240.0.0.1", "255.255.255.255",
])
func rejectsNonPublicRanges(_ ip: String) {
    #expect(!isPublicIPv4(ip))
}
