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

let rows = classify(state)
print("\n--- Summary ---")
print("icon:", connectionKind(interfaces: rows, primaryInterface: state.primaryInterface))
print("active:", activeInterface(interfaces: rows, primaryInterface: state.primaryInterface)?.bsdName ?? "—")
print("via:", viaInterface(interfaces: rows, primaryInterface: state.primaryInterface)?.bsdName ?? "—")
print("public:", (try? await PublicIPService().fetchPublicIP()) ?? "unavailable")

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

// `--watch` runs the live NetworkMonitor and prints every change until interrupted.
if CommandLine.arguments.contains("--watch") {
    setvbuf(stdout, nil, _IOLBF, 0)
    let monitor = NetworkMonitor()
    monitor.start()
    print("\n--- Watching (Ctrl-C to stop) ---")
    var last = ""
    while true {
        let rows = monitor.interfaces.map { "\($0.bsdName)=\($0.ipv4 ?? "—")" }.joined(separator: " ")
        let line = "\(monitor.connection) | via \(monitor.viaInterface?.bsdName ?? "—") | public \(monitor.publicIP) | \(rows)"
        if line != last {
            print(Date.now.formatted(date: .omitted, time: .standard), line)
            last = line
        }
        try await Task.sleep(for: .milliseconds(200))
    }
}
