//
//  EditorImageLoader.swift
//  MarkEditMac
//
//  Created by cyan on 5/29/25.
//

import WebKit
import UniformTypeIdentifiers
import MarkEditKit

/// URL scheme handler to load local images.
///
/// E.g., image-loader://Image.png
final class EditorImageLoader: NSObject, WKURLSchemeHandler, @unchecked Sendable {
  static let scheme = "image-loader"
  private let getBaseURL: () -> URL?

  init(getBaseURL: @escaping () -> URL?) {
    self.getBaseURL = getBaseURL
  }

  func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    guard let url = urlSchemeTask.request.url else {
      return Logger.assertFail("Invalid url scheme task: \(urlSchemeTask)")
    }

    guard let baseURL = getBaseURL() else {
      return Logger.log(.error, "Invalid baseURL for task: \(urlSchemeTask)")
    }

    let fileName = url.absoluteString.replacingOccurrences(of: "\(Self.scheme)://", with: "")
    let fileURL = baseURL.appending(path: fileName.removingPercentEncoding ?? fileName, directoryHint: .notDirectory)
    let fileData = (try? Data(contentsOf: fileURL)) ?? Data()
    let mimeType = UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType
    let contentLength = fileData.count

    let response = URLResponse(
      url: url,
      mimeType: mimeType,
      expectedContentLength: contentLength,
      textEncodingName: nil
    )

    urlSchemeTask.didReceive(response)
    urlSchemeTask.didReceive(fileData)
    urlSchemeTask.didFinish()
  }

  func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    // no-op
  }
}
