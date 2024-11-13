// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MarkEditCore",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    .library(
      name: "MarkEditCore",
      targets: ["MarkEditCore"]
    ),
  ],
  dependencies: [
    .package(path: "../MarkEditTools"),
  ],
  targets: [
    .target(
      name: "MarkEditCore",
      path: "Sources",
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency")
      ],
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),

    .testTarget(
      name: "MarkEditCoreTests",
      dependencies: ["MarkEditCore"],
      path: "Tests",
      resources: [
        .process("Files"),
      ],
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
  ]
)
