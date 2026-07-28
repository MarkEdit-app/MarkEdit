//
//  CompactCodableEnum.swift
//
//  Created by cyan on 7/28/26.
//

import Foundation

/// Hand-rolled `Codable` for payload-free enums, the synthesized one is expensive.
///
/// Swift generates a keyed container plus nested coding keys for every case, which costs
/// a few KB per enum. This keeps the exact same `{"caseName": {}}` representation so
/// existing UserDefaults values stay readable, and also accepts a plain `"caseName"` string.
public protocol CompactCodableEnum: RawRepresentable, Codable where RawValue == String {}

public extension CompactCodableEnum {
  init(from decoder: any Decoder) throws {
    if let name = try? decoder.singleValueContainer().decode(String.self), let value = Self(rawValue: name) {
      self = value
      return
    }

    let container = try decoder.container(keyedBy: CaseNameCodingKey.self)
    guard let key = container.allKeys.first, let value = Self(rawValue: key.stringValue) else {
      throw DecodingError.dataCorrupted(
        DecodingError.Context(
          codingPath: decoder.codingPath,
          debugDescription: "Unrecognized \(Self.self) value"
        )
      )
    }

    self = value
  }

  func encode(to encoder: any Encoder) throws {
    guard let key = CaseNameCodingKey(stringValue: rawValue) else {
      return
    }

    var container = encoder.container(keyedBy: CaseNameCodingKey.self)
    _ = container.nestedContainer(keyedBy: CaseNameCodingKey.self, forKey: key)
  }
}

// MARK: - Private

private struct CaseNameCodingKey: CodingKey {
  let stringValue: String
  var intValue: Int? { nil }

  init?(stringValue: String) {
    self.stringValue = stringValue
  }

  init?(intValue: Int) {
    return nil
  }
}
