// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ComfyNotch",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .library(name: "ComfyNotch", targets: ["ComfyNotch"]),
        .executable(name: "ComfyNotchDev", targets: ["ComfyNotchDev"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ComfyNotch",
            dependencies: [],
            path: "Sources/ComfyNotch"
        ),
        .executableTarget(
            name: "ComfyNotchDev",
            dependencies: ["ComfyNotch"],
            path: "Sources/ComfyNotchDev"
        )
    ]
)
