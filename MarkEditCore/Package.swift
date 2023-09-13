// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MarkEditCore",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
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
