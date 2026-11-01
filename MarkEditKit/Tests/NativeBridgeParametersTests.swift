//
//  NativeBridgeParametersTests.swift
//
//  Created by cyan on 11/1/26.
//

import MarkEditCore
import MarkEditKit
import XCTest

@MainActor
final class NativeBridgeParametersTests: XCTestCase {
  func testOptionalArgumentsAndSynchronousMethods() async throws {
    let module = CompletionModule()
    let bridge = module.bridge
    for json in ["{}", #"{"insert":null}"#, #"{"insert":"text"}"#] {
      let result = await bridge.invoke(method: "commitCompletion", parameters: Data(json.utf8))
      guard case .success(let value) = result else {
        return XCTFail("Expected success")
      }
      XCTAssertNil(value)
    }

    XCTAssertEqual(module.insertions.count, 3)
    XCTAssertNil(module.insertions[0])
    XCTAssertNil(module.insertions[1])
    XCTAssertEqual(module.insertions[2], "text")
  }

  func testNestedArgumentsDecodeBeforeNativeInvocation() async throws {
    let module = CompletionModule()
    let data = Data("""
    {"anchor":{"text":"hello","pos":2,"offset":10},"fullText":"hello world","userInitiated":true}
    """.utf8)
    let result = await module.bridge.invoke(method: "requestCompletions", parameters: data)
    guard case .success(let value) = result else {
      return XCTFail("Expected success")
    }

    XCTAssertNil(value)
    XCTAssertEqual(module.anchor?.text, "hello")
    XCTAssertEqual(module.anchor?.pos, 2)
    XCTAssertEqual(module.fullText, "hello world")
    XCTAssertTrue(try XCTUnwrap(module.userInitiated))
  }

  func testZeroArgumentAndUnknownMethodsIgnoreInvalidPayload() async {
    let module = CompletionModule()
    let bridge = module.bridge
    let invalid = Data("invalid".utf8)
    let result = await bridge.invoke(method: "cancelCompletion", parameters: invalid)
    guard case .success(let value) = result else {
      return XCTFail("Expected success")
    }

    XCTAssertNil(value)
    XCTAssertEqual(module.cancellations, 1)

    let unknown = await bridge.invoke(method: "missing", parameters: invalid)
    XCTAssertNil(unknown)
    XCTAssertEqual(module.cancellations, 1)
  }

  func testAsyncCallsKeepArgumentsIndependentAcrossSuspension() async {
    let module = TranslationModule()
    let bridge = module.bridge
    let first = Task { @MainActor in
      let response = await bridge.invoke(
        method: "translate",
        parameters: Data(#"{"text":"first","from":"en"}"#.utf8)
      )

      guard case .success(let value) = response else {
        return XCTFail("Expected first response")
      }

      XCTAssertEqual(value as? String, "first:en:nil")
    }

    await fulfillment(of: [module.started], timeout: 5)
    let second = await bridge.invoke(method: "translate", parameters: Data(#"{"text":"second","to":"fr"}"#.utf8))
    module.pending?.resume()
    module.pending = nil

    await first.value
    guard case .success(let value) = second else {
      return XCTFail("Expected second response")
    }

    XCTAssertEqual(value as? String, "second:nil:fr")
  }

  func testInvalidArgumentsDoNotInvokeNativeMethods() async throws {
  #if DEBUG
    throw XCTSkip("Run in Release: malformed bridge payloads intentionally assert in Debug.")
  #else
    let module = CompletionModule()
    let bridge = module.bridge
    for json in [
      "invalid", "null", "[]", "{}",
      #"{"anchor":{"text":"hello","pos":2,"offset":10},"userInitiated":"invalid"}"#,
    ] {
      let result = await bridge.invoke(method: "requestCompletions", parameters: Data(json.utf8))
      guard case .failure(let error) = result else {
        XCTFail("Expected decoding failure for \(json)")
        continue
      }
      XCTAssertTrue(error is DecodingError)
    }

    XCTAssertNil(module.anchor)
  #endif
  }
}

private extension NativeBridgeParametersTests {
  final class CompletionModule: NativeModuleCompletion {
    var insertions: [String?] = []
    var cancellations = 0
    var anchor: TextTokenizeAnchor?
    var fullText: String?
    var userInitiated: Bool?

    func requestCompletions(anchor: TextTokenizeAnchor, fullText: String?, userInitiated: Bool) {
      MainActor.preconditionIsolated()
      self.anchor = anchor
      self.fullText = fullText
      self.userInitiated = userInitiated
    }

    func commitCompletion(insert: String?) {
      MainActor.preconditionIsolated()
      insertions.append(insert)
    }

    func cancelCompletion() {
      MainActor.preconditionIsolated()
      cancellations += 1
    }

    func selectPrevious() {}
    func selectNext() {}
    func selectTop() {}
    func selectBottom() {}
  }

  final class TranslationModule: NativeModuleTranslation {
    let started = XCTestExpectation(description: "First translation suspended")
    var pending: CheckedContinuation<Void, Never>?

    func translate(text: String, from: String?, to: String?) async -> String {
      MainActor.preconditionIsolated()
      if text == "first" {
        await withCheckedContinuation { continuation in
          pending = continuation
          started.fulfill()
        }
      }

      MainActor.preconditionIsolated()
      return "\(text):\(from ?? "nil"):\(to ?? "nil")"
    }
  }
}
