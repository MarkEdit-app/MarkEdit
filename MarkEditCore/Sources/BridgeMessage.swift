//
//  BridgeMessage.swift
//
//  Created by cyan on 7/28/26.
//

import Foundation

/// Keyed payload sent to the web side, encoding fields dynamically.
///
/// Generated modules used to declare an `Encodable` struct per method, each one costing
/// a few KB of synthesized metadata. Output is identical, nil fields are omitted.
public struct BridgeMessage: Encodable {
  private let fields: [(name: String, value: any Encodable)]

  public init(_ fields: (String, any Encodable)...) {
    self.fields = fields.map { (name: $0.0, value: $0.1) }
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)

    for field in fields {
      try container.encode(field.value, forKey: field.name)
    }
  }
}

/// Coding key for bridge payloads, shared to avoid a `CodingKeys` enum per generated type.
public struct BridgeFieldKey: CodingKey {
  public let stringValue: String
  public var intValue: Int? { nil }

  public init(_ stringValue: String) {
    self.stringValue = stringValue
  }

  public init?(stringValue: String) {
    self.init(stringValue)
  }

  public init?(intValue: Int) {
    return nil
  }
}

public extension KeyedDecodingContainer where Key == BridgeFieldKey {
  /// Decodes a named field, treating absent and null the same way as an optional property.
  func value<T: Decodable>(_ name: String) throws -> T {
    let key = BridgeFieldKey(name)
    if contains(key), try !decodeNil(forKey: key) {
      return try decode(T.self, forKey: key)
    }

    guard let optional = T.self as? any ExpressibleByNilLiteral.Type, let value = optional.init(nilLiteral: ()) as? T else {
      throw DecodingError.keyNotFound(
        key,
        DecodingError.Context(
          codingPath: codingPath,
          debugDescription: "Missing parameter: \(name)"
        )
      )
    }

    return value
  }
}

public extension KeyedEncodingContainer where Key == BridgeFieldKey {
  /// Encodes a named field, omitting nil the same way as an optional property.
  mutating func encode(_ value: some Encodable, forKey name: String) throws {
    guard !((value as? any OptionalValue)?.isNil ?? false) else {
      return
    }

    try encode(value, forKey: BridgeFieldKey(name))
  }
}

// MARK: - Private

private protocol OptionalValue {
  var isNil: Bool { get }
}

extension Optional: OptionalValue {
  var isNil: Bool { self == nil }
}
