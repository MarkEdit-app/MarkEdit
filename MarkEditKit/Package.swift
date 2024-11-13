// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MarkEditKit",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    .library(
      name: "MarkEditKit",
      targets: ["MarkEditKit"]
    ),
  ],
  dependencies: [
    .package(path: "../MarkEditCore"),
    .package(path: "../MarkEditTools"),
  ],
  targets: [
    .target(
      name: "MarkEditKit",
      dependencies: ["MarkEditCore"],
      path: "Sources",
      swiftSettings: [
        .enableExperimentalFeature("StrictConcurrency")
      ],
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
  ]
)
