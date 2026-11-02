// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "ClipCopy", platforms: [.macOS("15.4")],
    products: [
        .executable(name: "ClipCopy", targets: ["ClipCopyApp"]),
        .executable(name: "ClipCopyDemo", targets: ["ClipCopyDemo"]),
        .executable(name: "ClipCopyChecks", targets: ["ClipCopyChecks"]),
        .executable(name: "ClipCopyTests", targets: ["ClipCopyTests"])
    ],
    targets: [
        .systemLibrary(name: "CSQLite"),
        .target(name: "ClipCopyCore"),
        .target(name: "ClipCopyStorage", dependencies: ["ClipCopyCore", "CSQLite"]),
        .target(name: "ClipCopyUI", dependencies: ["ClipCopyCore"]),
        .target(name: "ClipCopyNative", dependencies: ["ClipCopyCore", "ClipCopyStorage", "ClipCopyUI"]),
        .executableTarget(name: "ClipCopyApp", dependencies: ["ClipCopyNative", "ClipCopyUI"]),
        .executableTarget(name: "ClipCopyDemo", dependencies: ["ClipCopyUI"]),
        .executableTarget(name: "ClipCopyChecks", dependencies: ["ClipCopyNative", "ClipCopyUI"]),
        .executableTarget(name: "ClipCopyTests", dependencies: ["ClipCopyCore", "ClipCopyStorage", "ClipCopyNative", "ClipCopyUI", "CSQLite"], path: "Tests")
    ]
)
