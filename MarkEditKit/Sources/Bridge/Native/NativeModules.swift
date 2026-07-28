//
//  NativeModules.swift
//
//  Created by cyan on 12/24/22.
//

import Foundation

@MainActor
public protocol NativeBridge: AnyObject {
  static var name: String { get }

  func invoke(method: String, parameters: Data) async -> Result<Any?, Error>?
}

/**
 Native module that implements JavaScript functions.

 Don't implement NativeModule directly with controllers, it will easily introduce retain cycles.
 */
@MainActor
public protocol NativeModule: AnyObject {
  var bridge: NativeBridge { get }
}

@MainActor
public struct NativeModules {
  private let bridges: [String: NativeBridge]

  public init(modules: [NativeModule]) {
    self.bridges = modules.reduce(into: [String: NativeBridge]()) { result, module in
      let bridge = module.bridge
      result[type(of: bridge).name] = bridge
    }
  }
}

// MARK: - Internal

extension NativeModules {
  subscript(name: String) -> NativeBridge? {
    bridges[name]
  }
}
