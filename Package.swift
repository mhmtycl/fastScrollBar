// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FastScrollBar",
    platforms: [.iOS(.v26)],
    products: [
        .library(name: "FastScrollBar", targets: ["FastScrollBar"]),
        .library(name: "FastScrollBarDemo", targets: ["FastScrollBarDemo"]),
    ],
    targets: [
        .target(name: "FastScrollBar"),
        .target(name: "FastScrollBarDemo", dependencies: ["FastScrollBar"]),
    ]
)
