// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "swift-server",
    dependencies: [
        .package(url: "https://github.com/PerfectlySoft/Perfect-COpenSSL", from: "3.0.0")
    ],
    targets: [
        .target(name: "swift-server", dependencies: ["COpenSSL"])
    ]
)
