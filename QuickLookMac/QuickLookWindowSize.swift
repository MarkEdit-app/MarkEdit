//
//  QuickLookWindowSize.swift
//  QuickLookMac
//
//  Created by cyan on 8/26/26.
//

import AppKit

enum QuickLookWindowSize {
  static var savedValue: CGSize? {
    get {
      if let values = UserDefaults.standard.array(forKey: defaultsKey) as? [NSNumber], values.count == 2 {
        let size = CGSize(
          width: Double(truncating: values[0]),
          height: Double(truncating: values[1])
        )

        if size.width > 0, size.height > 0, size.width.isFinite, size.height.isFinite {
          return size
        }
      }

      return nil
    }
    set {
      if let newValue {
        UserDefaults.standard.set([newValue.width, newValue.height], forKey: defaultsKey)
      } else {
        UserDefaults.standard.removeObject(forKey: defaultsKey)
      }
    }
  }

  private static let defaultsKey = "SavedWindowSize"
}
