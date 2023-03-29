//
//  Grammarly.swift
//
//  Created by cyan on 1/5/23.
//

import AppKit
import MarkEditKit

/**
 Grammarly client for proofing: https://developer.grammarly.com/.
 */
public final class Grammarly {
  public static let shared = Grammarly()

  public var redirectHost: String {
    "grammarly-auth"
  }

  public func toggle(bridge: WebBridgeGrammarly) {
    enabled.toggle()
    update(bridge: bridge)
  }

  public func update(bridge: WebBridgeGrammarly) {
    if enabled {
      bridge.connect(clientID: clientID, redirectURI: redirectURI)
    } else {
      bridge.disconnect()
    }
  }

  public func startOAuth(bridge: WebBridgeGrammarly?) {
    self.bridge = bridge
  }

  public func completeOAuth(url: URL) {
    bridge?.completeOAuth(url: url.absoluteString)
    bridge = nil
  }

  // MARK: - Private

  private var enabled: Bool = false
  private weak var bridge: WebBridgeGrammarly?

  // It's OK to expose this key to an open-source project,
  // we use a free plan and added OAuth support, users can log in their accounts.
  //
  // https://developer.grammarly.com/plans
  private var clientID: String {
    "client_PaEKWbhCVjvUdbgwtsVHbX"
  }

  private var redirectURI: String {
    "markedit://\(redirectHost)"
  }

  private init() {}
}
