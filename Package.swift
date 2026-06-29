// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacVitals",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacVitals", targets: ["MacVitals"])
    ],
    targets: [
        .executableTarget(
            name: "MacVitals",
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("IOKit")
            ]
        )
    ]
)
