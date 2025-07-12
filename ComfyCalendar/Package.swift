// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "ComfyCalendar",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(
            name: "ComfyCalendar",
            targets: ["ComfyCalendar"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ComfyCalendar",
            path: "Sources/ComfyCalendar"
        )
    ]
)
