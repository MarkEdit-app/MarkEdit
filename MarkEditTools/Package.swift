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
      url: "https://github.com/realm/SwiftLint/releases/download/0.56.2/SwiftLintBinary-macos.artifactbundle.zip",
      checksum: "197df93d7f5041d8cd46d6902a34ad57914efe1b5b50635995f3b9065f2c3ffd"
    ),
    .plugin(
      name: "SwiftLint",
      capability: .buildTool(),
      dependencies: ["SwiftLintBinary"]
    ),
  ]
)
