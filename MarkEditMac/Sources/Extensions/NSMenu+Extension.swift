//
//  NSMenu+Extension.swift
//  MarkEditMac
//
//  Created by cyan on 5/26/25.
//

import AppKit

extension NSMenu {
  /**
   Hook this method to work around the **Populating a menu window that is already visible** crash.
   */
  static let swizzleIsUpdatedExcludingContentTypesOnce: () = {
    NSMenu.exchangeInstanceMethods(
      originalSelector: sel_getUid("_isUpdatedExcludingContentTypes:"),
      swizzledSelector: #selector(swizzled_isUpdatedExcludingContentTypes(_:))
    )
  }()

  /**
   The swizzled method handles differently when `needsHack` is flagged true.
   */
  var needsHack: Bool {
    get {
      (objc_getAssociatedObject(self, &AssociatedObjects.needsHack) as? Bool) ?? false
    }
    set {
      objc_setAssociatedObject(
        self,
        &AssociatedObjects.needsHack,
        newValue,
        objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN_NONATOMIC
      )
    }
  }

  func descendantNamed(_ title: String) -> NSMenuItem? {
    for item in items {
      if item.title == title {
        return item
      }

      if let descendant = item.submenu?.descendantNamed(title) {
        return descendant
      }
    }

    return nil
  }
}

// MARK: - Private

private extension NSMenu {
  enum AssociatedObjects {
    static var needsHack: UInt8 = 0
  }

  @objc func swizzled_isUpdatedExcludingContentTypes(_ contentTypes: Int) -> Bool {
    if needsHack {
      // The original implementation contains an invalid assertion that causes a crash.
      // Based on testing, it would return false anyway, so we simply return false to bypass the assertion.
      return false
    }

    return self.swizzled_isUpdatedExcludingContentTypes(contentTypes)
  }
}
