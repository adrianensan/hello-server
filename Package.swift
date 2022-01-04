// swift-tools-version:5.5
import PackageDescription

let useLocal = false

let opensslPackage: Package.Dependency
if useLocal {
  opensslPackage = .package(name: "OpenSSL",
                              path: "../openssl")
} else {
  opensslPackage = .package(name: "OpenSSL",
                            url: "git@github.com:adrianensan/openssl.git",
                            .branch("main"))
}

let package = Package(
    name: "ServerSideSwift",
    platforms: [.iOS(.v12), .macOS(.v10_15)],
    products: [.library(name:"ServerSideSwift", targets: ["ServerSideSwift"])],
    dependencies: [opensslPackage],
    targets: [
      .target(name: "ServerSideSwift", dependencies: ["OpenSSL"])
    ]
)
