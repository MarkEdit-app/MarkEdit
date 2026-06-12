// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MarkEditTools",
  platforms: [
    .iOS(.v26),
    .macOS(.v26),
  ],
  products: [
    .plugin(name: "SwiftLint", targets: ["SwiftLint"]),
  ],
  targets: [
    .binaryTarget(
      name: "SwiftLintBinary",
      url: "https://github.com/realm/SwiftLint/releases/download/0.64.1/SwiftLintBinary.artifactbundle.zip",
      checksum: "e04529befaa6d3c50d7acdb28cdfa61b3788d99da94a1bfc1132f267a94679b6"
    ),
    .plugin(
      name: "SwiftLint",
      capability: .buildTool(),
      dependencies: ["SwiftLintBinary"]
    ),
  ]
)
