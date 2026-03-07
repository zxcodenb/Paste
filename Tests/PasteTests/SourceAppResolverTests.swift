import AppKit
import XCTest
@testable import Paste

@MainActor
final class SourceAppResolverTests: XCTestCase {
    func testResolveReturnsApplicationDisplayNameAndIcon() {
        let expectedIcon = NSImage(size: NSSize(width: 16, height: 16))
        let resolver = SourceAppResolver(
            applicationURLProvider: { bundleIdentifier in
                XCTAssertEqual(bundleIdentifier, "com.example.safari")
                return URL(fileURLWithPath: "/Applications/Safari.app", isDirectory: true)
            },
            applicationInfoProvider: { _ in
                SourceAppDisplayInfo(displayName: "Safari", icon: expectedIcon)
            },
            runningAppInfoProvider: { _ in nil }
        )

        let info = resolver.resolve(bundleIdentifier: "com.example.safari")
        XCTAssertEqual(info.displayName, "Safari")
        XCTAssertNotNil(info.icon)
    }

    func testResolveFallsBackToBundleIdentifierWhenAppCannotBeResolved() {
        let resolver = SourceAppResolver(
            applicationURLProvider: { _ in nil },
            applicationInfoProvider: { _ in nil },
            runningAppInfoProvider: { _ in nil }
        )

        let info = resolver.resolve(bundleIdentifier: "com.example.unknown")
        XCTAssertEqual(info.displayName, "com.example.unknown")
        XCTAssertNil(info.icon)
    }

    func testResolveReturnsUnknownAppWhenBundleIdentifierIsNil() {
        let resolver = SourceAppResolver(
            applicationURLProvider: { _ in nil },
            applicationInfoProvider: { _ in nil },
            runningAppInfoProvider: { _ in nil }
        )

        let info = resolver.resolve(bundleIdentifier: nil)
        XCTAssertEqual(info.displayName, "Unknown App")
        XCTAssertNil(info.icon)
    }

    func testResolveCachesBundleIdentifierLookup() {
        var applicationURLLookups = 0
        let resolver = SourceAppResolver(
            applicationURLProvider: { _ in
                applicationURLLookups += 1
                return nil
            },
            applicationInfoProvider: { _ in nil },
            runningAppInfoProvider: { _ in nil }
        )

        _ = resolver.resolve(bundleIdentifier: "com.example.cached")
        _ = resolver.resolve(bundleIdentifier: "com.example.cached")

        XCTAssertEqual(applicationURLLookups, 1)
    }
}
