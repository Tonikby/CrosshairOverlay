// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "CrosshairOverlay",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .target(
            name: "CrosshairCore",
            path: "Sources/CrosshairCore"
        ),
        .executableTarget(
            name: "CrosshairOverlay",
            dependencies: ["CrosshairCore"],
            path: "Sources/CrosshairOverlay"
        ),
        .testTarget(
            name: "CrosshairOverlayTests",
            dependencies: ["CrosshairCore"]
        )
    ]
)
