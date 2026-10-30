import Foundation
import NetworkMenuBarKit
import SystemConfiguration

dump(SystemStateReader().read())

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
