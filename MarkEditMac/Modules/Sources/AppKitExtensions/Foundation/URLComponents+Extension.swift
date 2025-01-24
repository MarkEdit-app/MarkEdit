//
//  URLComponents+Extension.swift
//
//  Created by cyan on 1/24/25.
//

import Foundation

public extension URLComponents {
  var queryDict: [String: String]? {
    queryItems?.reduce(into: [:]) { result, item in
      result[item.name] = item.value
    }
  }
}
