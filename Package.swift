// swift-tools-version:5.6
import PackageDescription

let useLocal = true

let opensslPackage: Package.Dependency
if useLocal {
  opensslPackage = .package(name: "OpenSSL", path: "../openssl")
} else {
  opensslPackage = .package(url: "https://github.com:adrianensan/openssl",
                            branch: "main")
}

let package = Package(
    name: "ServerSideSwift",
    platforms: [.iOS(.v14), .macOS(.v11)],
    products: [
      .library(name: "HelloLog", targets: ["HelloLog"]),
      .library(name: "ServerSideSwift", targets: ["ServerSideSwift"]),
      .executable(name: "HelloTestServer", targets: ["HelloTestServer"])
    ],
    dependencies: [opensslPackage],
    targets: [
      .target(name: "HelloLog",
              swiftSettings: [.define("DEBUG", .when(configuration: .debug))]),
      .target(name: "ServerSideSwift",
              dependencies: ["HelloLog",
                             .product(name: "OpenSSL", package: "OpenSSL")],
              swiftSettings: [.define("DEBUG", .when(configuration: .debug))]),
      .executableTarget(name: "HelloTestServer",
                        dependencies: ["ServerSideSwift"],
                        swiftSettings: [.define("DEBUG", .when(configuration: .debug))])
    ]
)
