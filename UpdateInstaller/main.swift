//
//  main.swift
//  UpdateInstaller
//
//  Created by cyan on 8/2/26.
//

import Foundation
import Security
import UpdaterCore

/// The app this service is embedded in, nil when it isn't where it is expected to be.
let hostBundlePath = HostBundle.path(ofServiceAt: Bundle.main.bundleURL)

// Re-executed by the service itself to install the update once the app has quit
if CommandLine.arguments.contains(InstallerArguments.installFlag) {
  UpdateRunner.run()
  exit(0)
}

let delegate = ServiceDelegate()
let listener = NSXPCListener.service()

listener.delegate = delegate
listener.resume()

final class ServiceDelegate: NSObject, NSXPCListenerDelegate {
  func listener(
    _ listener: NSXPCListener,
    shouldAcceptNewConnection connection: NSXPCConnection
  ) -> Bool {
    guard let requirement = Self.clientRequirement else {
      return false
    }

    connection.setCodeSigningRequirement(requirement)
    connection.exportedInterface = NSXPCInterface(with: UpdateInstalling.self)
    connection.exportedObject = UpdateService()
    connection.resume()
    return true
  }

  /// Only the app this service is embedded in may drive it.
  private static let clientRequirement: String? = {
    guard let hostBundlePath,
          let requirement = try? BundleVerifier.designatedRequirement(of: hostBundlePath) else {
      return nil
    }

    var text: CFString?
    guard SecRequirementCopyString(requirement, [], &text) == errSecSuccess else {
      return nil
    }

    return text as String?
  }()
}
