// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "MarkEditTools",
  platforms: [
    .iOS(.v18),
    .macOS(.v15),
  ],
  products: [
    .plugin(name: "SwiftLint", targets: ["SwiftLint"]),
  ],
  targets: [
    .binaryTarget(
      name: "SwiftLintBinary",
      url: "https://github.com/realm/SwiftLint/releases/download/0.65.0/SwiftLintBinary.artifactbundle.zip",
      checksum: "eb333bd76dfb5f46d21fdf3615fe39bb938956ca0b8e94c241c4b2db6e696b90"
    ),
    .plugin(
      name: "SwiftLint",
      capability: .buildTool(),
      dependencies: ["SwiftLintBinary"]
    ),
  ]
)
