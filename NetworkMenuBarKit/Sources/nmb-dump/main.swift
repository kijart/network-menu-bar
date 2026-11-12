import Foundation
import NetworkMenuBarKit
import SystemConfiguration

if CommandLine.arguments.contains("--help") {
    print("""
    Usage: nmb-dump [--raw] [--watch]

    Prints the raw system state, the menu rows, the connection summary and the public IP.

      --raw    Also print the State:/Network keys of the dynamic store, to identify VPN clients
               that don't register a service (Tunnelblick, AWS VPN Client).
      --watch  Then run the live NetworkMonitor and print every change until Ctrl-C.
    """)
    exit(0)
}

let state = SystemStateReader().read()
dump(state)

print("\n--- Rows ---")
for row in classify(state) {
    let provider = row.vpnProvider.map { "\($0)" } ?? "-"
    print(row.kind, row.bsdName, row.name ?? "-", provider, row.ipv4 ?? "—", separator: "\t")
}

let rows = classify(state)
print("\n--- Summary ---")
print("connection:", connectionKind(interfaces: rows, primaryInterface: state.primaryInterface))
print("active:", activeInterface(interfaces: rows, primaryInterface: state.primaryInterface)?.bsdName ?? "—")
print("via:", viaInterface(interfaces: rows, primaryInterface: state.primaryInterface, routeInterface: state.routeInterface)?.bsdName ?? "—")
print("public:", (try? await PublicIPService().fetchPublicIP()) ?? "unavailable")

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
