// swift-tools-version: 5.9
import PackageDescription

let package = Package(
  name: "Rocket",
  platforms: [.macOS(.v13)],
  products: [.executable(name: "Rocket", targets: ["Rocket"])],
  targets: [
    .target(name: "RocketCore"),
    .executableTarget(name: "Rocket", dependencies: ["RocketCore"]),
    .testTarget(name: "RocketCoreTests", dependencies: ["RocketCore"]),
  ]
)
