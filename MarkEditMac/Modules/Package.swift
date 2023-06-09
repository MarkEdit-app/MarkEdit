// swift-tools-version: 5.8
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Modules",
  platforms: [
    .macOS(.v12),
  ],
  products: [
    .library(
      name: "AppKitControls",
      targets: ["AppKitControls"]
    ),
    .library(
      name: "AppKitExtensions",
      targets: ["AppKitExtensions"]
    ),
    .library(
      name: "FontPicker",
      targets: ["FontPicker"]
    ),
    .library(
      name: "Previewer",
      targets: ["Previewer"]
    ),
    .library(
      name: "Proofing",
      targets: ["Proofing"]
    ),
    .library(
      name: "SettingsUI",
      targets: ["SettingsUI"]
    ),
    .library(
      name: "TextBundle",
      targets: ["TextBundle"]
    ),
    .library(
      name: "TextCompletion",
      targets: ["TextCompletion"]
    ),
  ],
  dependencies: [
    .package(path: "../MarkEditKit"),
    .package(path: "../MarkEditTools"),
  ],
  targets: [
    .target(
      name: "AppKitControls",
      dependencies: ["AppKitExtensions"],
      path: "Sources/AppKitControls",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
    .target(
      name: "AppKitExtensions",
      path: "Sources/AppKitExtensions",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
    .target(
      name: "FontPicker",
      dependencies: ["AppKitExtensions"],
      path: "Sources/FontPicker",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
    .target(
      name: "Previewer",
      dependencies: ["MarkEditKit", "AppKitExtensions"],
      path: "Sources/Previewer",
      resources: [
        .process("Resources"),
      ],
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
    .target(
      name: "Proofing",
      dependencies: ["MarkEditKit"],
      path: "Sources/Proofing",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
    .target(
      name: "SettingsUI",
      dependencies: ["AppKitExtensions"],
      path: "Sources/SettingsUI",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
    .target(
      name: "TextBundle",
      path: "Sources/TextBundle",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
    .target(
      name: "TextCompletion",
      path: "Sources/TextCompletion",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),

    .testTarget(
      name: "ModulesTests",
      dependencies: [
        "AppKitExtensions",
        "TextBundle",
      ],
      path: "Tests",
      resources: [
        .copy("Files/sample.textbundle"),
      ],
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
  ]
)
