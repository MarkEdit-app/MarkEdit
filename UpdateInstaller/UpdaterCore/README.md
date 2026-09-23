# UpdaterCore

This package provides the trust rules for in-place app updates: code signature verification and the naming of staging directories.

It is used by `UpdateInstaller`, the XPC service that installs updates, and is deliberately free of any app or UI dependency.

## Tests

The shared `UpdaterCoreTests` scheme includes both XCTest and Swift Testing tests.
From the repository root, run it with Xcode 27:

```sh
DEVELOPER_DIR=/Applications/Xcode_27.0.app/Contents/Developer \
  xcodebuild test \
  -workspace UpdateInstaller/UpdaterCore/.swiftpm/xcode/package.xcworkspace \
  -scheme UpdaterCoreTests \
  -destination 'platform=macOS'
```

The same scheme is available through `MarkEdit.xcodeproj` for CI. The package's
Xcode build-tool plugin requires Xcode; standalone `swift test` does not provide
the `XcodeProjectPlugin` module.
