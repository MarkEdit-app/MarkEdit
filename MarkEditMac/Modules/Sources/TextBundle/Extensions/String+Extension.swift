//
//  String+Extension.swift
//
//  Created by cyan on 3/23/23.
//

import Foundation

public extension String {
  /// https://textbundle.org/spec/
  var isTextBundle: Bool {
    self == "org.textbundle.package"
  }
}
