// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MarkEditKit",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
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
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
  ]
)
