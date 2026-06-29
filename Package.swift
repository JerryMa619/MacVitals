// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MacVitals",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .executable(name: "MacVitals", targets: ["MacVitals"])
    ],
    targets: [
        .executableTarget(
            name: "MacVitals",
            resources: [
                .process("Resources")
            ],
            linkerSettings: [
                .linkedFramework("AppKit"),
                .linkedFramework("SwiftUI"),
                .linkedFramework("IOKit"),
                .linkedFramework("ServiceManagement"),
                .linkedFramework("UserNotifications")
            ]
        )
    ]
)
