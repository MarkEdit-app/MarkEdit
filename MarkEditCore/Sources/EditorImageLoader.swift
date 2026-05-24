//
//  EditorImageLoader.swift
//
//  Created by cyan on 5/29/25.
//

import WebKit
import UniformTypeIdentifiers
import os.log

/// URL scheme handler to load local images.
///
/// E.g., image-loader://Image.png
public final class EditorImageLoader: NSObject, WKURLSchemeHandler {
  public static let scheme = "image-loader"
  private let getBaseURL: () -> URL?

  public init(getBaseURL: @escaping () -> URL?) {
    self.getBaseURL = getBaseURL
  }

  public func webView(_ webView: WKWebView, start urlSchemeTask: WKURLSchemeTask) {
    guard let url = urlSchemeTask.request.url else {
      urlSchemeTask.didFailWithError(URLError(.badURL))
      return assertionFailure("Invalid url scheme task")
    }

    guard let baseURL = getBaseURL() else {
      urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
      return os_logger.log(level: .error, "Invalid baseURL")
    }

    let fileName = url.absoluteString.replacingOccurrences(of: "\(Self.scheme)://", with: "")
    let fileURL = baseURL.appending(path: fileName.removingPercentEncoding ?? fileName, directoryHint: .notDirectory)

    if let fileData = try? Data(contentsOf: fileURL) {
      let response = URLResponse(
        url: url,
        mimeType: UTType(filenameExtension: fileURL.pathExtension)?.preferredMIMEType,
        expectedContentLength: fileData.count,
        textEncodingName: nil
      )

      urlSchemeTask.didReceive(response)
      urlSchemeTask.didReceive(fileData)
      urlSchemeTask.didFinish()
    } else {
      let response = HTTPURLResponse(
        url: url,
        statusCode: 404,
        httpVersion: nil,
        headerFields: nil
      )

      if let response {
        urlSchemeTask.didReceive(response)
        urlSchemeTask.didFinish()
      } else {
        urlSchemeTask.didFailWithError(URLError(.fileDoesNotExist))
        assertionFailure("Failed to create 404 response")
      }
    }
  }

  public func webView(_ webView: WKWebView, stop urlSchemeTask: WKURLSchemeTask) {
    // no-op
  }
}

private let os_logger = os.Logger()
