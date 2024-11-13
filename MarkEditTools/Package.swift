// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MarkEditTools",
  platforms: [
    .iOS(.v17),
    .macOS(.v14),
  ],
  products: [
    .plugin(name: "SwiftLint", targets: ["SwiftLint"]),
  ],
  targets: [
    .binaryTarget(
      name: "SwiftLintBinary",
      url: "https://github.com/realm/SwiftLint/releases/download/0.58.2/SwiftLintBinary.artifactbundle.zip",
      checksum: "f2de7c148dba39bf0ad55ada8f60b15dde383c643c69f7eb2448bd2ed532f659"
    ),
    .plugin(
      name: "SwiftLint",
      capability: .buildTool(),
      dependencies: ["SwiftLintBinary"]
    ),
  ]
)
