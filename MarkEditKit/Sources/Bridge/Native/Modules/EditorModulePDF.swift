import Foundation

@MainActor
public protocol EditorModulePDFDelegate: AnyObject {
  func editorPDF(_ sender: EditorModulePDF, generate html: String, fileName: String?) async -> Bool
}

public final class EditorModulePDF: NativeModulePDF {
  private weak var delegate: EditorModulePDFDelegate?

  public init(delegate: EditorModulePDFDelegate) {
    self.delegate = delegate
  }

  public func generate(html: String, fileName: String?) async -> Bool {
    await delegate?.editorPDF(self, generate: html, fileName: fileName) == true
  }
}
