//
//  BridgeParameters.swift
//
//  Created by cyan on 11/1/26.
//

/// Shares decoding metadata across native methods while callers read strongly typed fields.
public struct BridgeParameters: Decodable {
  public let container: KeyedDecodingContainer<BridgeFieldKey>

  public init(from decoder: any Decoder) throws {
    container = try decoder.container(keyedBy: BridgeFieldKey.self)
  }
}
