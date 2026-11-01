//
//  BridgeParametersTests.swift
//
//  Created by cyan on 11/1/26.
//

import MarkEditCore
import XCTest

final class BridgeParametersTests: XCTestCase {
  private struct Message: Decodable, Equatable {
    let text: String
    let optional: Int?
    let list: [String]
    let nested: [String: Bool]

    init(text: String, optional: Int?, list: [String], nested: [String: Bool]) {
      self.text = text
      self.optional = optional
      self.list = list
      self.nested = nested
    }

    init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: BridgeFieldKey.self)
      text = try container.value("text")
      optional = try container.value("optional")
      list = try container.value("list")
      nested = try container.value("nested")
    }
  }

  private func decodeShared(_ data: Data) throws -> Message {
    let container = try JSONDecoder().decode(BridgeParameters.self, from: data).container
    return try Message(
      text: container.value("text"),
      optional: container.value("optional"),
      list: container.value("list"),
      nested: container.value("nested")
    )
  }

  func testMatchesPreviousMessageDecoding() throws {
    for optional in ["", #","optional":null"#, #","optional":42"#] {
      let data = Data("""
      {"text":"value","list":["a","b"],"nested":{"enabled":false},"unknown":true\(optional)}
      """.utf8)
      XCTAssertEqual(try decodeShared(data), try JSONDecoder().decode(Message.self, from: data))
    }
  }

  func testInvalidPayloadsPreserveErrorsAndCodingPaths() {
    for json in [
      "invalid", "null", "[]", "42", "\"text\"", "{}",
      #"{"text":null,"list":[],"nested":{}}"#,
      #"{"text":"value","optional":"invalid","list":[],"nested":{}}"#,
      #"{"text":"value","list":[42],"nested":{}}"#,
      #"{"text":"value","list":[],"nested":{"enabled":"invalid"}}"#,
    ] {
      let data = Data(json.utf8)
      let previous = Result { try JSONDecoder().decode(Message.self, from: data) }
      let shared = Result { try decodeShared(data) }
      guard case .failure(let previousError) = previous,
            case .failure(let sharedError) = shared else {
        XCTFail("Both decoders must reject \(json)")
        continue
      }

      let previousContext: DecodingError.Context
      let sharedContext: DecodingError.Context
      switch (previousError, sharedError) {
      case let (DecodingError.dataCorrupted(lhs), DecodingError.dataCorrupted(rhs)),
           let (DecodingError.valueNotFound(_, lhs), DecodingError.valueNotFound(_, rhs)),
           let (DecodingError.typeMismatch(_, lhs), DecodingError.typeMismatch(_, rhs)):
        previousContext = lhs
        sharedContext = rhs
      case let (DecodingError.keyNotFound(lhsKey, lhs), DecodingError.keyNotFound(rhsKey, rhs)):
        XCTAssertEqual(lhsKey.stringValue, rhsKey.stringValue)
        previousContext = lhs
        sharedContext = rhs
      default:
        XCTFail("Different decoding errors: \(previousError), \(sharedError)")
        continue
      }

      XCTAssertEqual(previousContext.codingPath.map(\.stringValue), sharedContext.codingPath.map(\.stringValue))
      XCTAssertEqual(previousContext.codingPath.map(\.intValue), sharedContext.codingPath.map(\.intValue))
      XCTAssertEqual(previousContext.debugDescription, sharedContext.debugDescription)

      let previousUnderlying = previousContext.underlyingError as NSError?
      let sharedUnderlying = sharedContext.underlyingError as NSError?
      XCTAssertEqual(previousUnderlying?.domain, sharedUnderlying?.domain)
      XCTAssertEqual(previousUnderlying?.code, sharedUnderlying?.code)
    }
  }

  func testContainerOutlivesDecoderAndIsIndependentOfLaterDecodes() throws {
    let container = try {
      let decoder = JSONDecoder()
      let first = try decoder.decode(BridgeParameters.self, from: Data(#"{"text":"first"}"#.utf8))
      let second = try decoder.decode(BridgeParameters.self, from: Data(#"{"text":"second"}"#.utf8))
      let text: String = try second.container.value("text")
      XCTAssertEqual(text, "second")
      return first.container
    }()

    let text: String = try container.value("text")
    XCTAssertEqual(text, "first")
  }

  func testStrategiesAndUserInfoArePreserved() throws {
    struct Value: Decodable {
      let text: String
      let context: String?

      init(from decoder: any Decoder) throws {
        text = try decoder.singleValueContainer().decode(String.self)
        let key = try XCTUnwrap(CodingUserInfoKey(rawValue: "context"))
        context = decoder.userInfo[key] as? String
      }
    }

    let decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .secondsSince1970
    decoder.dataDecodingStrategy = .base64

    let key = try XCTUnwrap(CodingUserInfoKey(rawValue: "context"))
    decoder.userInfo[key] = "retained"

    let data = Data(#"{"created_at":123,"file_data":"aGk=","context_value":"text"}"#.utf8)
    let container = try decoder.decode(BridgeParameters.self, from: data).container
    let date: Date = try container.value("createdAt")
    let bytes: Data = try container.value("fileData")
    let value: Value = try container.value("contextValue")
    XCTAssertEqual(date, Date(timeIntervalSince1970: 123))
    XCTAssertEqual(bytes, Data("hi".utf8))
    XCTAssertEqual(value.text, "text")
    XCTAssertEqual(value.context, "retained")
  }
}
