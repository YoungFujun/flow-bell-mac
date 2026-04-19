import AppKit
import Foundation

@MainActor
final class InstalledAppsStore: ObservableObject {
    @Published private(set) var apps: [BlockedApp] = []

    init() {
        reload()
    }

    func reload() {
        let roots = [
            URL(fileURLWithPath: "/Applications"),
            URL(fileURLWithPath: "/System/Applications"),
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications")
        ]

        var discovered = Set<BlockedApp>()
        for root in roots where FileManager.default.fileExists(atPath: root.path) {
            guard let enumerator = FileManager.default.enumerator(
                at: root,
                includingPropertiesForKeys: [.isApplicationKey, .nameKey, .isDirectoryKey],
                options: [.skipsHiddenFiles, .skipsPackageDescendants]
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                guard url.pathExtension == "app" else { continue }
                if let bundle = Bundle(url: url),
                   let bundleID = bundle.bundleIdentifier,
                   let name = bundle.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String ?? bundle.object(forInfoDictionaryKey: "CFBundleName") as? String {
                    discovered.insert(BlockedApp(bundleIdentifier: bundleID, displayName: name))
                }
            }
        }

        apps = discovered.sorted { lhs, rhs in
            lhs.displayName.localizedCaseInsensitiveCompare(rhs.displayName) == .orderedAscending
        }
    }

    func search(_ query: String, excluding existing: [BlockedApp]) -> [BlockedApp] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let existingIDs = Set(existing.map(\.bundleIdentifier))
        let base = apps.filter { !existingIDs.contains($0.bundleIdentifier) }
        guard !trimmed.isEmpty else {
            return Array(base.prefix(8))
        }
        return base
            .filter {
                $0.displayName.localizedCaseInsensitiveContains(trimmed) ||
                $0.bundleIdentifier.localizedCaseInsensitiveContains(trimmed)
            }
            .prefix(8)
            .map { $0 }
    }
}
