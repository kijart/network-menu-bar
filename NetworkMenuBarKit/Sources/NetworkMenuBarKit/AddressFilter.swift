import Network

/// Whether an interface address is worth showing: a valid IPv4 that is neither loopback nor link-local.
public func isUsablePrivateIPv4(_ address: String) -> Bool {
    guard let ip = IPv4Address(address) else { return false }
    let octets = Array(ip.rawValue)
    return octets[0] != 127 && !(octets[0] == 169 && octets[1] == 254)
}
