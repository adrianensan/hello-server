// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "ServerSideSwift",
    products: [.library(name:"ServerSideSwift", targets: ["ServerSideSwift"])],
    dependencies: [.package(url: "https://github.com/PerfectlySoft/Perfect-COpenSSL", from: "3.0.0")],
    targets: [.target(name: "ServerSideSwift", dependencies: ["COpenSSL"])]
)
