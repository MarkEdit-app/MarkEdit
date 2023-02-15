//
//  NSCursor+Extension.swift
//
//  Created by cyan on 2/15/23.
//

import AppKit

/**
 Calling deprecated methods is usually considered dangerous and is not recommended,
 use this protocol to suppress the warning while keeping compile-time safety.
 */
protocol NSCursorDeprecated: AnyObject {
  /**
   Apple says this method is "unused and should not be called", Apple lied.

   This method does have effects and it fixes some weird cursor style issues.
   */
  func setOnMouseEntered(_ flag: Bool)
}

extension NSCursor: NSCursorDeprecated {}
