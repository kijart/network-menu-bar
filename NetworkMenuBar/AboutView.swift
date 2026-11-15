import AppKit
import SwiftUI

struct AboutView: View {
    private let website = URL(string: "https://kijart.github.io/network-menu-bar/")!
    private let issues = URL(string: "https://github.com/kijart/network-menu-bar/issues")!
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
            HStack(spacing: 6) {
                Link("Website", destination: website)
                Text(verbatim: "·").foregroundStyle(.tertiary)
                Link("Issues", destination: issues)
                Text(verbatim: "·").foregroundStyle(.tertiary)
                Link("Source code", destination: repository)
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
