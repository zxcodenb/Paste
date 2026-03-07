import AppKit
import Foundation

struct SourceAppDisplayInfo {
    let displayName: String
    let icon: NSImage?
}

protocol SourceAppResolving {
    func resolve(bundleIdentifier: String?) -> SourceAppDisplayInfo
}

final class SourceAppResolver: SourceAppResolving {
    private let applicationURLProvider: (String) -> URL?
    private let applicationInfoProvider: (URL) -> SourceAppDisplayInfo?
    private let runningAppInfoProvider: (String) -> SourceAppDisplayInfo?

    private var cache: [String: SourceAppDisplayInfo] = [:]

    private let nilBundleCacheKey = "__nil_bundle_identifier__"

    init(
        applicationURLProvider: @escaping (String) -> URL? = { bundleIdentifier in
            NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
        },
        applicationInfoProvider: @escaping (URL) -> SourceAppDisplayInfo? = { appURL in
            let bundle = Bundle(url: appURL)
            let displayName = (bundle?.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)
            let bundleName = (bundle?.object(forInfoDictionaryKey: kCFBundleNameKey as String) as? String)?
                .trimmingCharacters(in: .whitespacesAndNewlines)

            let name = [displayName, bundleName]
                .compactMap { $0 }
                .first { !$0.isEmpty }
                ?? ""

            return SourceAppDisplayInfo(
                displayName: name,
                icon: NSWorkspace.shared.icon(forFile: appURL.path)
            )
        },
        runningAppInfoProvider: @escaping (String) -> SourceAppDisplayInfo? = { bundleIdentifier in
            guard let app = NSRunningApplication.runningApplications(withBundleIdentifier: bundleIdentifier).first else {
                return nil
            }

            let name = app.localizedName?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                ?? ""
            return SourceAppDisplayInfo(displayName: name, icon: app.icon)
        }
    ) {
        self.applicationURLProvider = applicationURLProvider
        self.applicationInfoProvider = applicationInfoProvider
        self.runningAppInfoProvider = runningAppInfoProvider
    }

    func resolve(bundleIdentifier: String?) -> SourceAppDisplayInfo {
        let normalizedBundleIdentifier = normalizedName(from: bundleIdentifier)
        let cacheKey = normalizedBundleIdentifier ?? nilBundleCacheKey

        if let cached = cache[cacheKey] {
            return cached
        }

        let resolved = resolveUncached(bundleIdentifier: normalizedBundleIdentifier)
        cache[cacheKey] = resolved
        return resolved
    }

    private func resolveUncached(bundleIdentifier: String?) -> SourceAppDisplayInfo {
        guard let bundleIdentifier else {
            return SourceAppDisplayInfo(displayName: "Unknown App", icon: nil)
        }

        if let appURL = applicationURLProvider(bundleIdentifier),
           let info = applicationInfoProvider(appURL) {
            let displayName = normalizedName(from: info.displayName) ?? bundleIdentifier
            return SourceAppDisplayInfo(displayName: displayName, icon: info.icon)
        }

        if let info = runningAppInfoProvider(bundleIdentifier) {
            let displayName = normalizedName(from: info.displayName) ?? bundleIdentifier
            return SourceAppDisplayInfo(displayName: displayName, icon: info.icon)
        }

        return SourceAppDisplayInfo(displayName: bundleIdentifier, icon: nil)
    }

    private func normalizedName(from rawName: String?) -> String? {
        guard let rawName = rawName?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !rawName.isEmpty else {
            return nil
        }
        return rawName
    }
}
