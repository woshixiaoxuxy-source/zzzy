// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "历史粘贴板",
    platforms: [
        .macOS(.v13)
    ],
    targets: [
        .executableTarget(
            name: "HistoryClipboard",
            path: "Sources/HistoryClipboard",
            swiftSettings: [
                .unsafeFlags(["-parse-as-library"])
            ]
        )
    ]
)
