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
    update(bridge: bridge, wasReset: false)
  }

  public func update(bridge: WebBridgeGrammarly, wasReset: Bool) {
    DispatchQueue.afterDelay(seconds: (enabled && wasReset) ? 0.5 : 0.0) {
      if self.enabled {
        bridge.connect(clientID: self.clientID, redirectURI: self.redirectURI)
      } else {
        bridge.disconnect()
      }
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
