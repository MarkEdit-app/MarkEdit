// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "UpdaterCore",
  platforms: [
    .macOS(.v26),
  ],
  products: [
    .library(
      name: "UpdaterCore",
      targets: ["UpdaterCore"]
    ),
  ],
  dependencies: [
    .package(path: "../../MarkEditTools"),
  ],
  targets: [
    .target(
      name: "UpdaterCore",
      path: "Sources",
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency")
      ],
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),

    .testTarget(
      name: "UpdaterCoreTests",
      dependencies: ["UpdaterCore"],
      path: "Tests",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
  ]
)
