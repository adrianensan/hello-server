// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "ServerSideSwift",
    products: [.library(name:"OpenSSL", targets: ["OpenSSL"]),
               .library(name:"ServerSideSwift", targets: ["ServerSideSwift"])],
    dependencies: [],
    targets: [
      .systemLibrary(
        name: "OpenSSL",
        pkgConfig: "openssl",
        providers: [
          .apt(["openssl libssl-dev"]),
          .brew(["openssl@1.1"]),
        ]
      ),
      .target(name: "ServerSideSwift", dependencies: ["OpenSSL"])]
)
