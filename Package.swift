// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "TailTallyCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "TailTallyCore", targets: ["TailTallyCore"])],
    targets: [.target(name: "TailTallyCore"), .testTarget(name: "TailTallyCoreTests", dependencies: ["TailTallyCore"])]
)
