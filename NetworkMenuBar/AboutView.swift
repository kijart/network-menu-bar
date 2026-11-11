import AppKit
import SwiftUI

struct AboutView: View {
    private let repository = URL(string: "https://github.com/kijart/network-menu-bar")!
    private let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "—"

    var body: some View {
        VStack(spacing: 8) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 96, height: 96)
                .accessibilityHidden(true)
            Text(verbatim: "Network Menu Bar")
                .font(.title2.weight(.semibold))
            Text("Version \(version)")
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
            Link(destination: repository) {
                Text(verbatim: "github.com/kijart/network-menu-bar")
            }
            Text("MIT License")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
        }
        .padding(24)
        .frame(width: 380)
    }
}
