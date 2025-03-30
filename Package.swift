// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "ComfyNotch",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(
            name: "ComfyNotch",
            targets: ["ComfyNotch"]
        ),
    ],
    dependencies: [],
    targets: [
        .executableTarget(
            name: "ComfyNotch",
            dependencies: [],
            path: "Sources/ComfyNotch"
        )
    ]
)
