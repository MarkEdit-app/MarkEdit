//
//  Previewer.swift
//
//  Created by cyan on 1/7/23.
//

import AppKit
import AppKitExtensions
import WebKit
import MarkEditKit

/**
 Previewer for diagrams (mermaid), math (katex) and table (gfm) etc.
 */
public final class Previewer: NSViewController {
  private enum Constants {
    static let popoverSize: Double = 390
    static let minimumHeight: Double = 160
  }

  private let code: String
  private let type: PreviewType

  private lazy var webView = {
    let controller = WKUserContentController()
    controller.addUserScript(resizeObserver)
    controller.add(MessageHandler(host: self), name: "bridge")

    let config: WKWebViewConfiguration = .newConfig()
    config.userContentController = controller

    let webView = WKWebView(frame: .zero, configuration: config)
    webView.allowsMagnification = true
    return webView
  }()

  public init(code: String, type: PreviewType) {
    self.code = code
    self.type = type
    super.init(nibName: nil, bundle: nil)
  }

  @available(*, unavailable)
  required init?(coder: NSCoder) {
    fatalError("init(coder:) has not been implemented")
  }

  override public func loadView() {
    // The initial size is minimum, it will be updated by resizeObserver
    view = NSView(frame: CGRect(x: 0, y: 0, width: Constants.popoverSize, height: Constants.minimumHeight))
  }

  override public func viewDidLoad() {
    super.viewDidLoad()

    struct Wrapper: Encodable {
      let code: String
    }

    let data = Wrapper(code: code).jsonEncoded
    let html = indexHtml?.replacingOccurrences(of: "\"{{DATA}}\"", with: data)

    webView.loadHTMLString(html ?? "", baseURL: nil)
    view.addSubview(webView)
  }

  override public func viewDidLayout() {
    super.viewDidLayout()
    webView.frame = view.bounds
  }

  private var indexHtml: String? {
    guard let path = Bundle.module.url(forResource: type.rawValue, withExtension: "html") else {
      fatalError("Missing \(type.rawValue).html to set up the editor")
    }

    return try? Data(contentsOf: path).toString()
  }

  /// Observe body size change and update content size accordingly.
  private var resizeObserver: WKUserScript {
    let source = """
    const observer = new ResizeObserver(entries => {
      requestAnimationFrame(() => {
        const height = entries[0].target.clientHeight;
        window.webkit.messageHandlers.bridge.postMessage({ height: Math.min(height, 640) });
        if (height <= \(Constants.minimumHeight)) {
          const style = document.head.appendChild(document.createElement("style"));
          style.appendChild(document.createTextNode(`
            html, body {
              height: \(Constants.minimumHeight)px;
            }
            #container {
              display: flex;
              align-items: center;
              justify-content: center;
              height: 100%;
              padding: 0px !important;
            }`
          ));
        }
      });
    });
    observer.observe(document.body);
    """
    return WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
  }
}

// MARK: - WKScriptMessageHandler

private extension Previewer {
  // Break the retain cycle inside message handler,
  // to keep it simple, we are not using a delegate here.
  class MessageHandler: NSObject, WKScriptMessageHandler {
    private weak var host: Previewer?

    init(host: Previewer? = nil) {
      self.host = host
    }

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
      host?.didReceive(message: message)
    }
  }

  func didReceive(message: WKScriptMessage) {
    if let body = message.body as? [String: Double], let height = body["height"], height > 0 {
      popover?.contentSize = CGSize(width: view.frame.width, height: max(height, Constants.minimumHeight))
    }
  }
}
