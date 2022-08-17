// swift-tools-version:5.7
import PackageDescription

let useLocal = !#file.contains("/DerivedData/") 

var dependencies: [Package.Dependency] = []
var additionalTargets: [Target] = []
let opensslTargetDependency: Target.Dependency
let helloCorePackage: Package.Dependency
if useLocal {
  helloCorePackage = .package(name: "hello-core", path: "../hello-core")
} else {
  helloCorePackage = .package(name: "server-side-swift", path: "../../../Hello/packages/server-side-swift")
}
dependencies.append(helloCorePackage)
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
    name: "HelloServer",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
      .library(name: "HelloServer", targets: ["HelloServer"]),
      .executable(name: "HelloTestServer", targets: ["HelloTestServer"])
    ],
    dependencies: dependencies,
    targets: additionalTargets + [
      .target(name: "HelloServer",
              dependencies: [
                .product(name: "HelloCore", package: "hello-core"),
                opensslTargetDependency,
              ],
              path: "code",
              swiftSettings: [.define("DEBUG", .when(configuration: .debug))]),
      .executableTarget(name: "HelloTestServer",
                        dependencies: ["HelloServer"],
                        resources: [.copy("static")],
                        swiftSettings: [.define("DEBUG", .when(configuration: .debug))])
    ]
)
