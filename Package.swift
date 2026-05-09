// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TrelloClient",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "TrelloClient", targets: ["TrelloClient"]),
    ],
    targets: [
        .target(
            name: "TrelloClient",
            dependencies: [],
            path: "Sources/TrelloClient"
        ),
    ]
)
