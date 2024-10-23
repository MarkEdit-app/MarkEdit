//
//  EditorChunkLoader.swift
//  MarkEditMac
//
//  Created by cyan on 9/2/24.
//

import WebKit
import MarkEditKit

/// URL scheme handler to load bundle chunks.
///
/// E.g., chunk-loader://chunks/index-DN_-g6jS.js
class EditorChunkLoader: NSObject, WKURLSchemeHandler, @unchecked Sendable {
  static let scheme = "chunk-loader"

  func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    guard let url = urlSchemeTask.request.url, let host = url.host(), host == "chunks" else {
      return Logger.assertFail("Invalid url scheme task: \(urlSchemeTask)")
    }

    guard let fileURL = Bundle.main.url(forResource: "\(host)/\(url.path())", withExtension: nil) else {
      return Logger.assertFail("Invalid request url: \(url)")
    }

    guard let fileData = try? Data(contentsOf: fileURL) else {
      return Logger.assertFail("Invalid file url: \(fileURL)")
    }

    guard let contentType = Self.mimeTypes[url.pathExtension] else {
      return Logger.assertFail("Invalid content type: \(url.pathExtension)")
    }

    let headerFields = Self.accessControl.merging(["Content-Type": contentType]) { current, _ in
      current
    }

    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: headerFields
    ) ?? URLResponse(
      url: url,
      mimeType: nil,
      expectedContentLength: 0,
      textEncodingName: nil
    )

    Logger.log(.info, "[\(Self.scheme)] Successfully loaded: \(url)")
    urlSchemeTask.didReceive(response)
    urlSchemeTask.didReceive(fileData)
    urlSchemeTask.didFinish()
  }

  func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    // no-op
  }
}

// MARK: - Private

private extension EditorChunkLoader {
  static let mimeTypes = [
    "js": "text/javascript",
    "css": "text/css",
    "woff2": "font/woff2",
  ]

  static let accessControl = [
    "Access-Control-Allow-Credentials": "true",
    "Access-Control-Allow-Headers": "*",
    "Access-Control-Allow-Methods": "*",
    "Access-Control-Allow-Origin": "*",
  ]
}
