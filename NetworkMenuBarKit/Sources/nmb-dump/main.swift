import Foundation
import NetworkMenuBarKit
import SystemConfiguration

let state = SystemStateReader().read()
dump(state)

print("\n--- Rows ---")
for row in classify(state) {
    let provider = row.vpnProvider.map { "\($0)" } ?? "-"
    print(row.kind, row.bsdName, row.name ?? "-", provider, row.ipv4 ?? "—", separator: "\t")
}

// `--raw` prints the dynamic store's network state keys, to identify VPN clients
// that don't register a service (Tunnelblick, AWS VPN Client).
if CommandLine.arguments.contains("--raw"),
   let store = SCDynamicStoreCreate(nil, "nmb-dump" as CFString, nil, nil),
   let keys = SCDynamicStoreCopyKeyList(store, "State:/Network/.*" as CFString) as? [String] {
    print("\n--- State:/Network keys ---")
    for key in keys.sorted() {
        print(key)
        if key.contains("utun") || key.hasSuffix("/IPv4") || key.contains("OpenVPN") {
            print(SCDynamicStoreCopyValue(store, key as CFString).map { "  \($0)" } ?? "")
        }
    }
}
