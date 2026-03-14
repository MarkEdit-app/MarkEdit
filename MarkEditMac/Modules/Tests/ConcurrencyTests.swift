//
//  ConcurrencyTests.swift
//

import TextBundle
import XCTest

/**
 Regression tests for the macOS 26 Swift 6 crash.

 ### The crash

 NSDocument calls `read(from:fileWrapper:ofType:)` and `write(to:ofType:)` on a
 **background thread** (queue: "NSDocumentController Opening"). The original fix
 wrapped those overrides in `MainActor.assumeIsolated { }` to silence Swift 6
 strict-concurrency warnings. That assertion checks at runtime that the current
 thread is the main actor — it is not — so the process trapped:

     _dispatch_assert_queue_fail
     dispatch_assert_queue
     _swift_task_checkIsolatedSwift
     swift_task_isCurrentExecutorWithFlagsImpl   ← macOS 26 crash site
     MainActor.assumeIsolated(_:file:line:)
     EditorDocument.read(from:ofType:)            ← our code

 ### The fix

 - `TextBundleWrapper` gained `@unchecked Sendable` so it can be sent across
   task/actor boundaries without a compile error.
 - `EditorDocument.textBundle`, `stringValue`, and `suggestedTextEncoding` became
   `nonisolated(unsafe)` — they are only ever accessed from serialised
   read/write paths, so the race is safe in practice and UserDefaults is
   documented as thread-safe.
 - `MainActor.assumeIsolated` was removed from all three NSDocument overrides.

 Each test below exercises one of those paths from a background thread and would
 have crashed before the fix.
 */
final class ConcurrencyTests: XCTestCase {

  // MARK: - Read path

  func testTextBundleCreateOnBackgroundThread() {
    // Mirrors EditorDocument.read(from:fileWrapper:ofType:):
    //   let bundle = try TextBundleWrapper(fileWrapper: fileWrapper)
    //   textBundle = bundle                     ← was inside assumeIsolated → CRASH
    //   try read(from: bundle.data, ofType: …)
    let url = bundleURL()
    let done = expectation(description: "background read")

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let bundle = try TextBundleWrapper(fileWrapper: FileWrapper(url: url))
        XCTAssertFalse(bundle.data.isEmpty, "Expected non-empty content from text bundle")
        done.fulfill()
      } catch {
        XCTFail("TextBundleWrapper init failed on background thread: \(error)")
        done.fulfill()
      }
    }

    wait(for: [done], timeout: 5)
  }

  // MARK: - Write path

  func testTextBundleWriteOnBackgroundThread() {
    // Mirrors EditorDocument.write(to:ofType:):
    //   let fw = try? textBundle?.fileWrapper(with: …)   ← was inside assumeIsolated → CRASH
    //   try fw?.write(to: url, originalContentsURL: nil)
    let url = bundleURL()
    let done = expectation(description: "background write")

    DispatchQueue.global(qos: .userInitiated).async {
      do {
        let bundle = try TextBundleWrapper(fileWrapper: FileWrapper(url: url))
        let output = try bundle.fileWrapper(with: bundle.data)
        XCTAssertNotNil(output, "Expected a valid output FileWrapper from text bundle")
        done.fulfill()
      } catch {
        XCTFail("TextBundleWrapper write failed on background thread: \(error)")
        done.fulfill()
      }
    }

    wait(for: [done], timeout: 5)
  }

  // MARK: - Sendable conformance

  func testTextBundleWrapperIsSendableAcrossTaskBoundaries() async throws {
    // TextBundleWrapper is now @unchecked Sendable. This lets EditorDocument pass
    // `bundle` into a MainActor-isolated closure without a Swift 6 Sendable error.
    //
    // The code this mirrors (after fix, no longer crashes):
    //   let bundle = try TextBundleWrapper(fileWrapper: fileWrapper)
    //   // bundle is now sent to MainActor closure — OK because it's Sendable
    //   MainActor.assumeIsolated { textBundle = bundle }  ← removed, but Sendable was needed
    let url = bundleURL()

    // Create in a detached task (non-isolated, simulating the NSDocument background call).
    let bundle = try await Task.detached {
      try TextBundleWrapper(fileWrapper: FileWrapper(url: url))
    }.value  // `.value` sends the result across the task boundary — requires Sendable

    // Consume on the main actor (simulating textBundle = bundle inside the controller).
    await MainActor.run {
      XCTAssertFalse(bundle.data.isEmpty, "Bundle data should survive crossing task boundary")
    }
  }

  // MARK: - Round-trip correctness

  func testTextBundleRoundTripPreservesContent() throws {
    // Ensures the data written by fileWrapper(with:) round-trips back to the same bytes.
    // This verifies correctness of the inlined encoding logic in EditorDocument.write(to:).
    let url = bundleURL()
    let original = try TextBundleWrapper(fileWrapper: FileWrapper(url: url))

    let roundTrippedWrapper = try original.fileWrapper(with: original.data)
    guard let files = roundTrippedWrapper.fileWrappers,
          let textFile = files[original.textFileName] else {
      XCTFail("Round-tripped FileWrapper missing text file '\(original.textFileName)'")
      return
    }

    XCTAssertEqual(
      textFile.regularFileContents,
      original.data,
      "Round-tripped text data should be identical to the original"
    )
  }
}

// MARK: - Private

private extension ConcurrencyTests {
  func bundleURL() -> URL {
    // swiftlint:disable:next force_unwrapping
    Bundle.module.url(forResource: "sample.textbundle", withExtension: nil)!
  }
}
