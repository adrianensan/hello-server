// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "ServerSideSwift",
    products: [.library(name:"ServerSideSwift", targets: ["ServerSideSwift"])],
    dependencies: [],
    targets: [.target(name: "ServerSideSwift", dependencies: ["OpenSSL"]),
              .target(name: "OpenSSL", dependencies: [])]
)
