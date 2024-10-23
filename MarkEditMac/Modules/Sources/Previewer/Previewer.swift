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
    static let maximumWidth: Double = 1280
  }

  private let code: String
  private let type: PreviewType

  private lazy var webView = {
    let controller = WKUserContentController()
    controller.addUserScript(resizeObserver)
    controller.add(MessageHandler(host: self), name: "bridge")

    let config: WKWebViewConfiguration = .newConfig()
    config.userContentController = controller

    let webView = PreviewWebView(frame: .zero, configuration: config)
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
    setTimeout(() => {
      const container = document.querySelector("#container");
      const bounds = document.querySelector("\(type.selector)").getBoundingClientRect();
      const width = bounds.width + 20;
      const height = bounds.height + 20;
      window.webkit.messageHandlers.bridge.postMessage({ width, height });
      container.style.width = `${Math.max(width, \(Constants.popoverSize))}px`;
      container.style.opacity = "1";
    }, 200);
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
      Task { @MainActor in
        host?.didReceive(message: message)
      }
    }
  }

  func didReceive(message: WKScriptMessage) {
    if let body = message.body as? [String: Double], let height = body["height"], height > 0 {
      popover?.contentSize = CGSize(
        width: max(min(body["width"] ?? view.frame.width, Constants.maximumWidth), Constants.popoverSize),
        height: max(height, Constants.minimumHeight)
      )
    }
  }
}

// MARK: - PreviewWebView

private final class PreviewWebView: WKWebView {
  override func willOpenMenu(_ menu: NSMenu, with event: NSEvent) {
    menu.items.forEach { item in
      // Hide the "Reload" item because it makes the content empty
      if item.identifier?.rawValue == "WKMenuItemIdentifierReload" {
        item.isHidden = true
      }

      #if !DEBUG
        // Hide the "Inspect Element" item for release builds,
        // because as soon as the popover dismisses, the inspector will be closed.
        if item.identifier?.rawValue == "WKMenuItemIdentifierInspectElement" {
          item.isHidden = true
        }
      #endif
    }

    super.willOpenMenu(menu, with: event)
  }
}

// MARK: - Private

private extension PreviewType {
  var selector: String {
    switch self {
    case .mermaid: return "svg"
    case .table: return "table"
    case .katex: return ".katex-display"
    }
  }
}
