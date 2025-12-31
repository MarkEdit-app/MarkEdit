//
//  NSPasteboard+Extension.swift
//
//  Created by cyan on 1/4/23.
//

import AppKit

public extension NSPasteboard {
  static var find: Self {
    Self(name: .find)
  }

  var hasText: Bool {
    pasteboardItems?.contains { $0.types.contains(.string) } == true
  }

  var string: String? {
    get {
      string(forType: .string)
    }
    set {
      guard let newValue else {
        return
      }

      declareTypes([.string], owner: nil)
      setString(newValue, forType: .string)
    }
  }

  func url() async -> String? {
    guard #available(macOS 15.4, *) else {
      guard let string else {
        return string(forType: .URL)
      }

      return NSDataDetector.extractURL(from: string)
    }

    // This alerts the user only when the pasteboard really contains links
    let values = try? await NSPasteboard.general.detectedValues(for: [\.links])
    return values?.links.first?.url.absoluteString
  }

  func overwrite(string: String?) {
    clearContents()

    if let string {
      setString(string, forType: .string)
    }
  }

  @MainActor
  func sanitize(lineBreak: String?) {
    // Handle the case where a link is only copied to "public.url",
    // for example, copying the link generated for iCloud Collaborate.
    if string?.isEmpty ?? true, let url = string(forType: .URL), !url.isEmpty {
      declareTypes([.string, .URL], owner: nil)
      setString(url, forType: .string)
      setString(url, forType: .URL)
    }

    // Handle the case where the pasted content has different line endings
    if let lineBreak, let sanitized = string?.sanitizing(lineBreak: lineBreak), sanitized != string {
      let savedItems = getDataItems()
      declareTypes([.string], owner: nil)
      setString(sanitized, forType: .string)

      // Interfering with the data to be pasted is challenging.
      //
      // The simplest solution is to change the data before pasting,
      // and restore it after a short delay.
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        self.setDataItems(savedItems)
      }
    }
  }
}

// MARK: - Private

private extension NSPasteboard {
  func getDataItems() -> [NSPasteboard.PasteboardType: Data] {
    (types ?? []).reduce(into: [NSPasteboard.PasteboardType: Data]()) { items, type in
      items[type] = data(forType: type)
    }
  }

  @discardableResult
  func setDataItems(_ items: [NSPasteboard.PasteboardType: Data]) -> Bool {
    var items = items
    legacyTypes.forEach {
      // Ensure legacy types are consistent to prevent the changes from being reverted
      items[.init($0.key)] = items[.init($0.value)]
    }

    var result = true
    declareTypes(Array(items.keys), owner: nil)

    for (type, data) in items {
      result = result && setData(data, forType: type)
    }

    return result
  }
}

private extension String {
  func sanitizing(lineBreak: String) -> String {
    // 1. \r\n -> \n
    // 2. \r -> \n
    // 3. \n -> lineBreak if necessary
    //
    // Order matters; it may not be the fastest, but it's easy to understand.
    var output = self
    output = output.replacingOccurrences(of: "\r\n", with: "\n")
    output = output.replacingOccurrences(of: "\r", with: "\n")

    if lineBreak != "\n" {
      output = output.replacingOccurrences(of: "\n", with: lineBreak)
    }

    return output
  }
}

private let legacyTypes = [
  "NSStringPboardType": "public.utf8-plain-text",
  "NSFilenamesPboardType": "public.file-url",
  "NeXT TIFF v4.0 pasteboard type": "public.tiff",
  "NeXT Rich Text Format v1.0 pasteboard type": "public.rtf",
  "NeXT RTFD pasteboard type": "com.apple.flat-rtfd",
  "Apple HTML pasteboard type": "public.html",
  "Apple Web Archive pasteboard type": "com.apple.webarchive",
  "Apple URL pasteboard type": "public.url",
  "Apple PDF pasteboard type": "com.adobe.pdf",
  "Apple PNG pasteboard type": "public.png",
  "NSColor pasteboard type": "com.apple.cocoa.pasteboard.color",
  "iOS rich content paste pasteboard type": "com.apple.uikit.attributedstring",
]
