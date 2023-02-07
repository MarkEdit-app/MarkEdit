//
//  String+Extension.swift
//
//  Created by cyan on 12/28/22.
//

import Foundation

public extension String {
  /// Overload of the String.Encoding version
  init?(data: Data, encoding: CFStringEncodings) {
    self.init(data: data, encoding: String.Encoding(from: encoding))
  }

  /// Overload of the String.Encoding version
  func data(using encoding: CFStringEncodings, allowLossyConversion: Bool = false) -> Data? {
    data(using: String.Encoding(from: encoding), allowLossyConversion: allowLossyConversion)
  }

  func toData(encoding: String.Encoding = .utf8) -> Data? {
    data(using: encoding)
  }
}

extension String.Encoding {
  init(from: CFStringEncodings) {
    let encoding = CFStringEncoding(from.rawValue)
    self.init(rawValue: CFStringConvertEncodingToNSStringEncoding(encoding))
  }
}
