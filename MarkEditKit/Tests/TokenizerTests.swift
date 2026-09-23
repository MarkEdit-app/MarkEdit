//
//  TokenizerTests.swift
//

import MarkEditCore
import MarkEditKit
import XCTest

@MainActor
final class TokenizerTests: XCTestCase {
  func testTokenBoundsUseUTF16Offsets() async {
    let module = EditorModuleTokenizer()
    let anchor = TextTokenizeAnchor(text: "😀 hello world", pos: 4, offset: 100)
    let bounds = await module.tokenize(anchor: anchor)

    XCTAssertEqual(bounds["from"] as? Int, 3)
    XCTAssertEqual(bounds["to"] as? Int, 8)
  }

  func testWordMovementPreservesDocumentOffset() async {
    let module = EditorModuleTokenizer()
    let anchor = TextTokenizeAnchor(text: "😀 hello world", pos: 4, offset: 100)
    let backward = await module.moveWordBackward(anchor: anchor)
    let forward = await module.moveWordForward(anchor: anchor)

    XCTAssertEqual(backward, 103)
    XCTAssertEqual(forward, 108)
  }

  func testEmptyTextFallsBackToOneCharacter() async {
    let module = EditorModuleTokenizer()
    let anchor = TextTokenizeAnchor(text: "", pos: 0, offset: 10)
    let backward = await module.moveWordBackward(anchor: anchor)
    let forward = await module.moveWordForward(anchor: anchor)

    XCTAssertEqual(backward, 9)
    XCTAssertEqual(forward, 11)
  }

  func testConcurrentRequestsKeepIndependentTokenizers() async {
    let module = EditorModuleTokenizer()
    let results = await withTaskGroup(of: Int.self, returning: [Int].self) { group in
      for length in 1...20 {
        group.addTask {
          await module.moveWordForward(anchor: TextTokenizeAnchor(
            text: String(repeating: "a", count: length),
            pos: 0,
            offset: 100
          ))
        }
      }

      var results = [Int]()
      for await result in group {
        results.append(result)
      }

      return results.sorted()
    }

    XCTAssertEqual(results, Array(101...120))
  }
}
