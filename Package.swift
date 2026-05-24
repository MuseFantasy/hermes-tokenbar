// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "HermesTokenBar",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "HermesTokenCore", targets: ["HermesTokenCore"]),
        .executable(name: "HermesTokenBar", targets: ["HermesTokenBar"]),
        .executable(name: "HermesTokenCoreSmokeTests", targets: ["HermesTokenCoreSmokeTests"]),
    ],
    targets: [
        .target(
            name: "HermesTokenCore",
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
        .executableTarget(
            name: "HermesTokenBar",
            dependencies: ["HermesTokenCore"],
            linkerSettings: [.linkedFramework("AppKit")]
        ),
        .executableTarget(
            name: "HermesTokenCoreSmokeTests",
            dependencies: ["HermesTokenCore"],
            linkerSettings: [.linkedLibrary("sqlite3")]
        ),
    ]
)
