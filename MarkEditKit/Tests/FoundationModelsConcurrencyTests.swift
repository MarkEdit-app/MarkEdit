//
//  FoundationModelsConcurrencyTests.swift
//

import MarkEditKit
import XCTest

@MainActor
final class FoundationModelsConcurrencyTests: XCTestCase {
  func testUnavailableStreamRepliesAsynchronouslyOnMainActor() async {
    let expectation = expectation(description: "Unavailable response")
    let delegate = Delegate(expectation: expectation)
    let module = EditorModuleFoundationModels(delegate: delegate)

    module.streamResponseTo(sessionID: nil, streamID: "stream", prompt: "", options: nil)
    XCTAssertNil(delegate.response)

    await fulfillment(of: [expectation])
    XCTAssertEqual(delegate.streamID, "stream")
    XCTAssertEqual(delegate.response?.error, "Model Unavailable")
    XCTAssertEqual(delegate.response?.done, true)
    XCTAssertNil(delegate.response?.content)
  }
}

private extension FoundationModelsConcurrencyTests {
  final class Delegate: EditorModuleFoundationModelsDelegate {
    let expectation: XCTestExpectation
    var streamID: String?
    var response: LanguageModelResponse?

    init(expectation: XCTestExpectation) {
      self.expectation = expectation
    }

    func editorFoundationModelsApplyStreamUpdate(
      _ sender: EditorModuleFoundationModels,
      streamID: String,
      response: LanguageModelResponse
    ) {
      MainActor.preconditionIsolated()
      self.streamID = streamID
      self.response = response
      expectation.fulfill()
    }
  }
}
