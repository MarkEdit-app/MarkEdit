// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MarkEditTools",
  platforms: [
    .iOS(.v16),
    .macOS(.v13),
  ],
  products: [
    .plugin(name: "SwiftLint", targets: ["SwiftLint"]),
  ],
  targets: [
    .binaryTarget(
      name: "SwiftLintBinary",
      url: "https://github.com/realm/SwiftLint/releases/download/0.52.4/SwiftLintBinary-macos.artifactbundle.zip",
      checksum: "8a8095e6235a07d00f34a9e500e7568b359f6f66a249f36d12cd846017a8c6f5"
    ),
    .plugin(
      name: "SwiftLint",
      capability: .buildTool(),
      dependencies: ["SwiftLintBinary"]
    ),
  ]
)
