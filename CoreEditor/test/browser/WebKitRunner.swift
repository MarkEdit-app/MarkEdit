import AppKit
import WebKit

@MainActor
final class BrowserTestRunner: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
  let view: WKWebView

  override init() {
    let configuration = WKWebViewConfiguration()
    configuration.websiteDataStore = .nonPersistent()

    view = WKWebView(frame: NSRect(x: 0, y: 0, width: 1200, height: 900), configuration: configuration)
    super.init()

    configuration.userContentController.add(self, name: "browserTests")
    view.navigationDelegate = self
  }

  func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
    guard let result = message.body as? [String: Any],
          let passed = result["passed"] as? Bool,
          let detail = result["message"] as? String else {
      print("FAIL: invalid browser test result")
      exit(1)
    }

    print("\(passed ? "PASS" : "FAIL"): \(detail)")
    exit(passed ? 0 : 1)
  }

  func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation?, withError error: Error) {
    print("FAIL: \(error)")
    exit(1)
  }

  func webView(_ webView: WKWebView, didFail navigation: WKNavigation?, withError error: Error) {
    print("FAIL: \(error)")
    exit(1)
  }
}

MainActor.assumeIsolated {
  guard CommandLine.arguments.count == 2, let url = URL(string: CommandLine.arguments[1]) else {
    print("Usage: WebKitRunner.swift <test-page-url>")
    exit(1)
  }

  let app = NSApplication.shared
  app.setActivationPolicy(.prohibited)

  let runner = BrowserTestRunner()
  runner.view.load(URLRequest(url: url))

  DispatchQueue.main.asyncAfter(deadline: .now() + 45) {
    print("FAIL: browser tests timed out")
    exit(1)
  }

  withExtendedLifetime(runner) {
    app.run()
  }
}
