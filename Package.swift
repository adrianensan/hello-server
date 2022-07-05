// swift-tools-version:5.6
import PackageDescription

let useLocal = true

var dependencies: [Package.Dependency] = []
var additionalTargets: [Target] = []
let opensslTargetDependency: Target.Dependency
#if os(iOS) || os(macOS)
let opensslPackage: Package.Dependency
if useLocal {
  opensslPackage = .package(name: "openssl", path: "../openssl")
} else {
  opensslPackage = .package(url: "https://github.com/adrianensan/openssl",
                            branch: "main")
}
dependencies.append(opensslPackage)
opensslTargetDependency = .product(name: "OpenSSL", package: "openssl")
#else
additionalTargets.append(.systemLibrary(name: "OpenSSL",
                                        pkgConfig: "openssl",
                                        providers: [.apt(["openssl libssl-dev"])]))
opensslTargetDependency = .target(name: "OpenSSL")
#endif

let package = Package(
    name: "ServerSideSwift",
    platforms: [.iOS(.v15), .macOS(.v11)],
    products: [
      .library(name: "HelloLog", targets: ["HelloLog"]),
      .library(name: "ServerSideSwift", targets: ["ServerSideSwift"]),
      .executable(name: "HelloTestServer", targets: ["HelloTestServer"])
    ],
    dependencies: dependencies,
    targets: additionalTargets + [
      .target(name: "HelloLog",
              swiftSettings: [.define("DEBUG", .when(configuration: .debug))]),
      .target(name: "ServerSideSwift",
              dependencies: ["HelloLog", opensslTargetDependency,
              ],
              swiftSettings: [.define("DEBUG", .when(configuration: .debug))]),
      .executableTarget(name: "HelloTestServer",
                        dependencies: ["ServerSideSwift"],
                        resources: [.copy("static")],
                        swiftSettings: [.define("DEBUG", .when(configuration: .debug))])
    ]
)
