//
//  EditorChunkLoader.swift
//  MarkEditiOS
//
//  WKURLSchemeHandler that serves CoreEditor's JS/CSS chunk files from the app bundle.
//  E.g., chunk-loader://chunks/index-DN_-g6jS.js
//

import WebKit
import MarkEditKit

final class EditorChunkLoader: NSObject, WKURLSchemeHandler {
  static let scheme = "chunk-loader"

  func webView(_ webView: WKWebView, start urlSchemeTask: any WKURLSchemeTask) {
    guard let url = urlSchemeTask.request.url, let host = url.host(), host == "chunks" else {
      Logger.assertFail("Invalid url scheme task: \(urlSchemeTask)")
      return
    }

    guard let fileURL = Bundle.main.url(forResource: "\(host)/\(url.path())", withExtension: nil) else {
      Logger.assertFail("Invalid request url: \(url)")
      return
    }

    guard let fileData = try? Data(contentsOf: fileURL) else {
      Logger.assertFail("Invalid file url: \(fileURL)")
      return
    }

    guard let contentType = Self.mimeTypes[url.pathExtension] else {
      Logger.assertFail("Invalid content type: \(url.pathExtension)")
      return
    }

    let headerFields = Self.accessControl.merging(["Content-Type": contentType]) { current, _ in current }

    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: headerFields
    ) ?? URLResponse(url: url, mimeType: nil, expectedContentLength: 0, textEncodingName: nil)

    urlSchemeTask.didReceive(response)
    urlSchemeTask.didReceive(fileData)
    urlSchemeTask.didFinish()
  }

  func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {
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
