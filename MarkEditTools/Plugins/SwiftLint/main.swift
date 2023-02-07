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
    return []
  }
}

extension Main: XcodeBuildToolPlugin {
  func createBuildCommands(context: XcodePluginContext, target: XcodeTarget) throws -> [Command] {
    [
      .buildCommand(
        displayName: "Running SwiftLint for \(target.displayName)",
        executable: try context.tool(named: "swiftlint").path,
        arguments: [
          "lint",
          "--strict",
          "--config",
          "\(context.xcodeProject.directory.string)/.swiftlint.yml",
          "--cache-path",
          "\(context.pluginWorkDirectory.string)/cache",
          context.xcodeProject.directory.string,
        ]
      ),
    ]
  }
}
