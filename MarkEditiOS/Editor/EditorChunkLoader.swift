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
    // Every code path must end with didFinish() or didFailWithError().
    // Leaving a task incomplete hangs the entire WKWebView page load.
    do {
      try serve(urlSchemeTask)
    } catch {
      print("[EditorChunkLoader] ✗ \(error.localizedDescription) — \(urlSchemeTask.request.url?.absoluteString ?? "nil")")
      urlSchemeTask.didFailWithError(error)
    }
  }

  func webView(_ webView: WKWebView, stop urlSchemeTask: any WKURLSchemeTask) {
    // no-op
  }
}

// MARK: - Private

private extension EditorChunkLoader {
  enum ChunkError: LocalizedError {
    case invalidURL(String)
    case fileNotFound(String)
    case unreadableFile(String)
    case unknownContentType(String)

    var errorDescription: String? {
      switch self {
      case .invalidURL(let u):           return "Invalid chunk-loader URL: \(u)"
      case .fileNotFound(let path):      return "Chunk not in bundle: \(path)"
      case .unreadableFile(let path):    return "Cannot read bundle file: \(path)"
      case .unknownContentType(let ext): return "No MIME type for extension: .\(ext)"
      }
    }
  }

  func serve(_ urlSchemeTask: any WKURLSchemeTask) throws {
    guard let url = urlSchemeTask.request.url, let host = url.host(), host == "chunks" else {
      throw ChunkError.invalidURL(urlSchemeTask.request.url?.absoluteString ?? "nil")
    }

    // url.path() already begins with "/", so concatenate directly to avoid a double-slash.
    // e.g. host="chunks", url.path()="/index-abc.js" → resourcePath="chunks/index-abc.js"
    let resourcePath = host + url.path()
    print("[EditorChunkLoader] → \(resourcePath)")

    // Primary lookup: relative path form "chunks/filename.js"
    let fileURL: URL
    if let found = Bundle.main.url(forResource: resourcePath, withExtension: nil) {
      fileURL = found
    } else if let found = Bundle.main.url(
      forResource: url.lastPathComponent,
      withExtension: nil,
      subdirectory: host
    ) {
      // Fallback: explicit subdirectory API for stricter bundle layouts
      fileURL = found
    } else {
      throw ChunkError.fileNotFound(resourcePath)
    }

    guard let fileData = try? Data(contentsOf: fileURL) else {
      throw ChunkError.unreadableFile(fileURL.path)
    }

    guard let contentType = mimeTypes[url.pathExtension] else {
      throw ChunkError.unknownContentType(url.pathExtension)
    }

    let headerFields = accessControl.merging(["Content-Type": contentType]) { current, _ in current }
    let response = HTTPURLResponse(
      url: url,
      statusCode: 200,
      httpVersion: nil,
      headerFields: headerFields
    ) ?? URLResponse(url: url, mimeType: contentType, expectedContentLength: fileData.count, textEncodingName: nil)

    print("[EditorChunkLoader] ✓ \(fileData.count) bytes — \(resourcePath)")
    urlSchemeTask.didReceive(response)
    urlSchemeTask.didReceive(fileData)
    urlSchemeTask.didFinish()
  }

  var mimeTypes: [String: String] {
    [
      "js": "text/javascript",
      "css": "text/css",
      "woff2": "font/woff2",
    ]
  }

  var accessControl: [String: String] {
    [
      "Access-Control-Allow-Credentials": "true",
      "Access-Control-Allow-Headers": "*",
      "Access-Control-Allow-Methods": "*",
      "Access-Control-Allow-Origin": "*",
    ]
  }
}
