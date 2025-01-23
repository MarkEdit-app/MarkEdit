//
//  WebModuleBridge.swift
//
//  Created by cyan on 12/16/22.
//

import WebKit

/**
 Wrapper for all web bridges.
 */
@MainActor
public struct WebModuleBridge {
  public let config: WebBridgeConfig
  public let core: WebBridgeCore
  public let completion: WebBridgeCompletion
  public let history: WebBridgeHistory
  public let lineEndings: WebBridgeLineEndings
  public let textChecker: WebBridgeTextChecker
  public let selection: WebBridgeSelection
  public let format: WebBridgeFormat
  public let search: WebBridgeSearch
  public let toc: WebBridgeTableOfContents
  public let api: WebBridgeAPI
  public let writingTools: WebBridgeWritingTools

  public init(webView: WKWebView) {
    self.config = WebBridgeConfig(webView: webView)
    self.core = WebBridgeCore(webView: webView)
    self.completion = WebBridgeCompletion(webView: webView)
    self.history = WebBridgeHistory(webView: webView)
    self.lineEndings = WebBridgeLineEndings(webView: webView)
    self.textChecker = WebBridgeTextChecker(webView: webView)
    self.selection = WebBridgeSelection(webView: webView)
    self.format = WebBridgeFormat(webView: webView)
    self.search = WebBridgeSearch(webView: webView)
    self.toc = WebBridgeTableOfContents(webView: webView)
    self.api = WebBridgeAPI(webView: webView)
    self.writingTools = WebBridgeWritingTools(webView: webView)
  }
}
