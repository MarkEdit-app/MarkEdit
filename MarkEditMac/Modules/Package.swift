// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
  name: "Modules",
  platforms: [
    .macOS(.v26),
  ],
  products: [
    .library(
      name: "SharedUI",
      targets: ["SharedUI"]
    ),
    .library(
      name: "AppKitExtensions",
      targets: ["AppKitExtensions"]
    ),
    .library(
      name: "DiffKit",
      targets: ["DiffKit"]
    ),
    .library(
      name: "ExtensionCore",
      targets: ["ExtensionCore"]
    ),
    .library(
      name: "FileDrop",
      targets: ["FileDrop"]
    ),
    .library(
      name: "FileVersion",
      targets: ["FileVersion"]
    ),
    .library(
      name: "FontPicker",
      targets: ["FontPicker"]
    ),
    .library(
      name: "SettingsUI",
      targets: ["SettingsUI"]
    ),
    .library(
      name: "Statistics",
      targets: ["Statistics"]
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
    .package(path: "../MarkEditCore"),
    .package(path: "../MarkEditKit"),
    .package(path: "../MarkEditTools"),
  ],
  targets: [
    .target(
      name: "SharedUI",
      dependencies: ["AppKitExtensions"],
      path: "Sources/SharedUI",
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
      name: "DiffKit",
      path: "Sources/DiffKit",
      resources: [
        .process("Resources"),
      ],
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
    .target(
      name: "ExtensionCore",
      dependencies: ["AppKitExtensions", "MarkEditCore", "MarkEditKit"],
      path: "Sources/ExtensionCore",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
    .target(
      name: "FileDrop",
      dependencies: ["AppKitExtensions", "MarkEditKit", "TextBundle"],
      path: "Sources/FileDrop",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
    .target(
      name: "FileVersion",
      dependencies: ["SharedUI", "MarkEditKit", "DiffKit"],
      path: "Sources/FileVersion",
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
      name: "SettingsUI",
      dependencies: ["AppKitExtensions"],
      path: "Sources/SettingsUI",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),
    .target(
      name: "Statistics",
      dependencies: ["AppKitExtensions", "MarkEditKit"],
      path: "Sources/Statistics",
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
      dependencies: ["AppKitExtensions"],
      path: "Sources/TextCompletion",
      plugins: [
        .plugin(name: "SwiftLint", package: "MarkEditTools"),
      ]
    ),

    .testTarget(
      name: "ModulesTests",
      dependencies: [
        "SharedUI",
        "AppKitExtensions",
        "ExtensionCore",
        "FileDrop",
        "Statistics",
        "TextBundle",
        "MarkEditKit",
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
