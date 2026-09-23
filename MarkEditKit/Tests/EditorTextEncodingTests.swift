//
//  EditorTextEncodingTests.swift
//

import MarkEditKit
import XCTest

@MainActor
final class EditorTextEncodingTests: XCTestCase {
  func testEncodingSnapshotsRoundTripInChildTasks() async {
    let results = await withTaskGroup(of: Bool.self, returning: [Bool].self) { group in
      for encoding in EditorTextEncoding.allCases {
        group.addTask {
          guard let data = encoding.encode(string: "Markdown\n") else {
            return false
          }

          return encoding.decode(data: data) == "Markdown\n"
        }
      }

      var results = [Bool]()
      for await result in group {
        results.append(result)
      }

      return results
    }

    XCTAssertEqual(results.count, EditorTextEncoding.allCases.count)
    XCTAssertTrue(results.allSatisfy { $0 })
  }
}
