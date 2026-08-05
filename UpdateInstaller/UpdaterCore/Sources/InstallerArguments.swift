//
//  InstallerArguments.swift
//
//  Created by cyan on 8/4/26.
//

import Foundation

/// Arguments shared by the launcher and detached installer.
public struct InstallerArguments: Equatable {
  public static let installFlag = "--install"
  public let stagedPath: String
  public let processIdentifier: Int32
  public let relaunch: Bool

  public init(stagedPath: String, processIdentifier: Int32, relaunch: Bool) {
    self.stagedPath = stagedPath
    self.processIdentifier = processIdentifier
    self.relaunch = relaunch
  }

  /// Returns nil for missing or malformed options.
  public init?(parsing arguments: [String]) {
    let options = Self.options(in: arguments)

    guard let stagedPath = options["--staged"], !stagedPath.isEmpty,
          let processIdentifier = options["--pid"].flatMap({ Int32($0) }) else {
      return nil
    }

    self.init(
      stagedPath: stagedPath,
      processIdentifier: processIdentifier,
      relaunch: options["--relaunch"] != nil
    )
  }

  public var commandLine: [String] {
    [
      Self.installFlag,
      "--staged", stagedPath,
      "--pid", "\(processIdentifier)",
    ] + (relaunch ? ["--relaunch"] : [])
  }
}

// MARK: - Private

private extension InstallerArguments {
  /// Values keyed by their option, flags map to an empty string.
  static func options(in arguments: [String]) -> [String: String] {
    var options = [String: String]()

    for (index, argument) in arguments.enumerated() where argument.hasPrefix("--") {
      let value = arguments[safe: index + 1] ?? ""
      options[argument] = value.hasPrefix("--") ? "" : value
    }

    return options
  }
}

private extension Array {
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
