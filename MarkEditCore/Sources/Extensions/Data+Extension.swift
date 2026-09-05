//
//  Data+Extension.swift
//
//  Created by cyan on 12/28/22.
//

import Foundation
import CryptoKit

public extension Data {
  var sha256Hash: String {
    SHA256.hash(data: self).map { String(format: "%02x", $0) }.joined()
  }

  var isProbablyBinary: Bool {
    // Treat a UTF-16 BOM as text
    if starts(with: [0xFE, 0xFF]) || starts(with: [0xFF, 0xFE]) {
      return false
    }

    var containsZero = false
    var couldBeLittleEndian = true
    var couldBeBigEndian = true

    // Scan the first 512 bytes for NULs and UTF-16 patterns
    for (offset, byte) in prefix(512).enumerated() {
      let isZero = byte == 0
      let isEven = offset.isMultiple(of: 2)
      containsZero = containsZero || isZero
      couldBeLittleEndian = couldBeLittleEndian && (isZero != isEven)
      couldBeBigEndian = couldBeBigEndian && (isZero == isEven)

      // NULs outside either UTF-16 pattern suggest binary
      if containsZero && !couldBeLittleEndian && !couldBeBigEndian {
        return true
      }
    }

    return false
  }

  /// Handle text encoding in Cocoa apps: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/introStrings.html.
  ///
  /// Ideally, the encoding for Markdown should always be utf-8 as described in: https://daringfireball.net/linked/2011/08/05/markdown-uti.
  func toString(encoding: String.Encoding = .utf8) -> String? {
    // Perfect, successfully decoded it with the preferred encoding
    if let decoded = String(data: self, encoding: encoding) {
      return decoded
    }

    // Oh no, guess the encoding since we failed to decode it directly
    var converted: NSString?
    NSString.stringEncoding(
      for: self,
      encodingOptions: [
        // Just a blind guess, it's not possible to know without extra information
        .suggestedEncodingsKey: [
          String.Encoding(from: .GB_18030_2000).rawValue,
          String.Encoding(from: .big5).rawValue,
          String.Encoding.japaneseEUC.rawValue,
          String.Encoding.shiftJIS.rawValue,
          String.Encoding(from: .EUC_KR).rawValue,
          encoding.rawValue,
        ],
      ],
      convertedString: &converted,
      usedLossyConversion: nil
    )

    // It can still be nil, in that case we should allow users to reopen with an encoding
    return converted as? String
  }
}
