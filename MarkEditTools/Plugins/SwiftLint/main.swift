//
//  SwiftLintPlugin.swift
//
//  Created by cyan on 1/30/23.
//

import PackagePlugin
import XcodeProjectPlugin

@main
struct Main: BuildToolPlugin {
  func createBuildCommands(context: PluginContext, target: Target) async throws -> [Command] {
    // XcodeBuildToolPlugin would be good enough
    []
  }
}

extension Main: XcodeBuildToolPlugin {
  func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
    [
      .buildCommand(
        displayName: "Running SwiftLint for \(target.displayName)",
        executable: try context.tool(named: "swiftlint").url,
        arguments: [
          "lint",
          "--strict",
          "--config",
          "\(context.xcodeProject.directoryURL.path(percentEncoded: false))/.swiftlint.yml",
          "--cache-path",
          "\(context.pluginWorkDirectoryURL.path(percentEncoded: false))/cache",
          context.xcodeProject.directoryURL.path(percentEncoded: false),
        ],
        environment: [:],
        inputFiles: [],
        outputFiles: []
      ),
    ]
  }
}
