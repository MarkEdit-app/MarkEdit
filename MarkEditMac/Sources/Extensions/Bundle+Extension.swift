//
//  Bundle+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 6/11/25.
//

import Foundation

extension Bundle {
  static let swizzleInfoDictionaryOnce: () = {
    guard #available(macOS 26.0, *), AppRuntimeConfig.useClassicInterface else {
      return
    }

    Bundle.exchangeInstanceMethods(
      originalSelector: #selector(getter: infoDictionary),
      swizzledSelector: #selector(getter: swizzled_infoDictionary)
    )
  }()

  @objc var swizzled_infoDictionary: [String: Any]? {
    var dict = self.swizzled_infoDictionary
    dict?["UIDesignRequiresCompatibility"] = true

    return dict
  }
}
