import Foundation
import SystemConfiguration

/// Calls `handler` when interface addresses, the primary interface or an OpenVPN tunnel change.
/// `NWPathMonitor` misses these when the path itself stays the same (split-tunnel VPNs, DHCP renewals).
final class DynamicStoreWatcher {
    static let patterns = [
        "State:/Network/Interface/[^/]+/IPv4",
        "State:/Network/Global/IPv4",
        "State:/Network/OpenVPN",
    ]

    private let handler: @Sendable () -> Void
    private var store: SCDynamicStore?

    init(handler: @escaping @Sendable () -> Void) {
        self.handler = handler
    }

    deinit {
        if let store {
            SCDynamicStoreSetDispatchQueue(store, nil)
        }
    }

    func start() {
        guard store == nil else { return }
        var context = SCDynamicStoreContext(
            version: 0,
            info: Unmanaged.passUnretained(self).toOpaque(),
            retain: nil, release: nil, copyDescription: nil
        )
        let callback: SCDynamicStoreCallBack = { _, _, info in
            guard let info else { return }
            Unmanaged<DynamicStoreWatcher>.fromOpaque(info).takeUnretainedValue().handler()
        }
        guard let store = SCDynamicStoreCreate(nil, "NetworkMenuBar.watch" as CFString, callback, &context) else { return }
        SCDynamicStoreSetNotificationKeys(store, nil, Self.patterns as CFArray)
        SCDynamicStoreSetDispatchQueue(store, DispatchQueue(label: "NetworkMonitor.store"))
        self.store = store
    }
}
