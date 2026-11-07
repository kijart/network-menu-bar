import Network

/// Whether an interface address is worth showing: a valid IPv4 that is neither loopback nor link-local.
public func isUsablePrivateIPv4(_ address: String) -> Bool {
    guard let ip = IPv4Address(address) else { return false }
    let octets = Array(ip.rawValue)
    return octets[0] != 127 && !(octets[0] == 169 && octets[1] == 254)
}

/// Whether a lookup response is a strict dotted-quad IPv4 in a publicly routable range.
/// `IPv4Address` alone accepts forms like "127.1", "0x7f.0.0.1" or "1.2.3.4%en0".
public func isPublicIPv4(_ address: String) -> Bool {
    let parts = address.split(separator: ".", omittingEmptySubsequences: false)
    guard parts.count == 4 else { return false }
    var octets: [Int] = []
    for part in parts {
        guard (1...3).contains(part.count),
              part.allSatisfy({ ("0"..."9").contains($0) }),
              part.count == 1 || part.first != "0",
              let value = Int(part), value <= 255 else { return false }
        octets.append(value)
    }
    let (a, b) = (octets[0], octets[1])
    return !(a == 0 || a == 10 || a == 127 || a >= 224
        || (a == 100 && (64...127).contains(b))
        || (a == 169 && b == 254)
        || (a == 172 && (16...31).contains(b))
        || (a == 192 && b == 168))
}
