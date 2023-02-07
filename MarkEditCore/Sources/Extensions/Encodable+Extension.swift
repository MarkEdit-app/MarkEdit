//
//  Encodable+Extension.swift
//
//  Created by cyan on 12/22/22.
//

import Foundation

public extension Encodable {
  var jsonEncoded: String {
    (try? JSONEncoder().encode(self).toString()) ?? "{}"
  }
}
