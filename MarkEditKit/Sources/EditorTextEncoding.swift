//
//  EditorTextEncoding.swift
//
//  Created by cyan on 1/4/23.
//

import Foundation

/// https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/Strings/Articles/readingFiles.html#//apple_ref/doc/uid/TP40003459-SW4.
///
/// We *can*, but don't want to, include all supported encodings, which makes the UI super complicated,
/// Markdown prefers utf-8 as mentioned here: https://daringfireball.net/linked/2011/08/05/markdown-uti.
public enum EditorTextEncoding: CaseIterable, CustomStringConvertible, Codable {
  // Derived from String.Encoding
  case ascii
  case nonLossyASCII
  case utf8
  case utf16
  case utf16BigEndian
  case utf16LittleEndian
  case macOSRoman
  case isoLatin1
  case windowsLatin1

  // Derived from CFStringEncodings
  case gb18030
  case big5
  case japaneseEUC
  case shiftJIS
  case koreanEUC

  public var description: String {
    switch self {
    case .ascii: return "ASCII"
    case .nonLossyASCII: return "Non-lossy ASCII"
    case .utf8: return "Unicode (UTF-8)"
    case .utf16: return "Unicode (UTF-16)"
    case .utf16BigEndian: return "Unicode (UTF-16BE)"
    case .utf16LittleEndian: return "Unicode (UTF-16LE)"
    case .macOSRoman: return "Western (Mac OS Roman)"
    case .isoLatin1: return "Western (ISO Latin 1)"
    case .windowsLatin1: return "Western (Windows Latin 1)"
    case .gb18030: return "Simplified Chinese (GB 18030)"
    case .big5: return "Traditional Chinese (Big 5)"
    case .japaneseEUC: return "Japanese (EUC)"
    case .shiftJIS: return "Japanese (Shift JIS)"
    case .koreanEUC: return "Korean (EUC)"
    }
  }

  public func encode(string: String) -> Data? {
    switch self {
    case .ascii: return string.data(using: .ascii)
    case .nonLossyASCII: return string.data(using: .nonLossyASCII)
    case .utf8: return string.data(using: .utf8)
    case .utf16: return string.data(using: .utf16)
    case .utf16BigEndian: return string.data(using: .utf16BigEndian)
    case .utf16LittleEndian: return string.data(using: .utf16LittleEndian)
    case .macOSRoman: return string.data(using: .macOSRoman)
    case .isoLatin1: return string.data(using: .isoLatin1)
    case .windowsLatin1: return string.data(using: .windowsCP1252)
    case .gb18030: return string.data(using: .GB_18030_2000)
    case .big5: return string.data(using: .big5)
    case .japaneseEUC: return string.data(using: .japaneseEUC)
    case .shiftJIS: return string.data(using: String.Encoding.shiftJIS)
    case .koreanEUC: return string.data(using: .EUC_KR)
    }
  }

  public func decode(data: Data, guessEncoding: Bool = false) -> String {
    let defaultResult = {
      switch self {
      case .ascii: return String(data: data, encoding: .ascii)
      case .nonLossyASCII: return String(data: data, encoding: .nonLossyASCII)
      case .utf8: return String(data: data, encoding: .utf8)
      case .utf16: return String(data: data, encoding: .utf16)
      case .utf16BigEndian: return String(data: data, encoding: .utf16BigEndian)
      case .utf16LittleEndian: return String(data: data, encoding: .utf16LittleEndian)
      case .macOSRoman: return String(data: data, encoding: .macOSRoman)
      case .isoLatin1: return String(data: data, encoding: .isoLatin1)
      case .windowsLatin1: return String(data: data, encoding: .windowsCP1252)
      case .gb18030: return String(data: data, encoding: .GB_18030_2000)
      case .big5: return String(data: data, encoding: .big5)
      case .japaneseEUC: return String(data: data, encoding: .japaneseEUC)
      case .shiftJIS: return String(data: data, encoding: String.Encoding.shiftJIS)
      case .koreanEUC: return String(data: data, encoding: .EUC_KR)
      }
    }()

    if let defaultResult {
      return defaultResult
    }

    if guessEncoding, let guessedResult = data.toString() {
      return guessedResult
    }

    return data.asciiText()
  }
}

public extension EditorTextEncoding {
  /// In menus, grouping cases with a separator.
  static var groupingCases: Set<Self> {
    Set([.nonLossyASCII, .utf16LittleEndian, .windowsLatin1, .big5, .shiftJIS])
  }
}

// MARK: - Private

private extension Data {
  func asciiText(unsupported: Character = ".") -> String {
    reduce(into: "") { result, byte in
      if (byte >= 32 && byte < 127) || (byte >= 160 && byte < 255) || byte == 0x0A || byte == 0x09 {
        result.append(Character(UnicodeScalar(byte)))
      } else {
        result.append(unsupported)
      }
    }
  }
}
