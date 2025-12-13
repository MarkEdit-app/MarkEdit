//
//  EditorSaveOptionsView.swift
//  MarkEditMac
//
//  Created by cyan on 12/17/24.
//

import AppKit
import SwiftUI
import SettingsUI
import MarkEditKit

/**
 Observable object to manage KVO observation of NSSavePanel.showsHiddenFiles.
 */
private final class PanelObserver: ObservableObject {
  @Published var showsHiddenFiles: Bool
  private var observation: NSKeyValueObservation?
  
  init(panel: NSSavePanel?) {
    self.showsHiddenFiles = panel?.showsHiddenFiles ?? AppPreferences.General.showHiddenFiles
    
    if let panel = panel {
      observation = panel.observe(\.showsHiddenFiles, options: [.new]) { [weak self] _, change in
        guard let self = self, let newValue = change.newValue else { return }
        // Only update if the value actually changed to avoid infinite loops
        guard self.showsHiddenFiles != newValue else { return }
        DispatchQueue.main.async {
          self.showsHiddenFiles = newValue
          AppPreferences.General.showHiddenFiles = newValue
        }
      }
    }
  }
}

/**
 Accessory view used in NSSavePanel to provide additional options.
 */
struct EditorSaveOptionsView: View {
  struct Options: OptionSet {
    let rawValue: Int
    static let fileExtension = Self(rawValue: 1 << 0)
    static let textEncoding = Self(rawValue: 1 << 1)
    static let showHiddenFiles = Self(rawValue: 1 << 2)
    static let savePanel: Self = [.fileExtension, .textEncoding]
    static let openPanel: Self = [.textEncoding, .showHiddenFiles]
  }

  enum Result {
    case fileExtension(value: NewFilenameExtension)
    case textEncoding(value: EditorTextEncoding)
    case showHiddenFiles(value: Bool)
  }

  @State private var filenameExtension = AppPreferences.General.newFilenameExtension
  @State private var textEncoding = AppPreferences.General.defaultTextEncoding
  @StateObject private var panelObserver: PanelObserver

  private let options: Options
  private let onValueChange: ((Result) -> Void)

  init(options: Options, panel: NSSavePanel? = nil, onValueChange: @escaping ((Result) -> Void)) {
    self.options = options
    self.onValueChange = onValueChange
    _panelObserver = StateObject(wrappedValue: PanelObserver(panel: panel))
  }

  static func wrapper(for options: Options, panel: NSSavePanel? = nil, onValueChange: @escaping ((Result) -> Void)) -> NSView {
    NSHostingView(rootView: Self(options: options, panel: panel, onValueChange: onValueChange))
  }

  var body: some View {
    SettingsForm(padding: 8) {
      Section {
        if options.contains(.fileExtension) {
          Picker(Localized.Document.fileExtension, selection: $filenameExtension) {
            ForEach(NewFilenameExtension.allCases, id: \.self) {
              Text($0.rawValue).tag($0)
            }
          }
          .onChange(of: filenameExtension) {
            onValueChange(.fileExtension(value: filenameExtension))
          }
          .formMenuPicker(minWidth: 120)
        }

        if options.contains(.textEncoding) {
          Picker(Localized.Document.textEncoding, selection: $textEncoding) {
            ForEach(EditorTextEncoding.allCases, id: \.self) {
              Text($0.description)

              if EditorTextEncoding.groupingCases.contains($0) {
                Divider()
              }
            }
          }
          .onChange(of: textEncoding) {
            onValueChange(.textEncoding(value: textEncoding))
          }
          .formMenuPicker(minWidth: 120)
        }

        if options.contains(.showHiddenFiles) {
          Toggle(isOn: $panelObserver.showsHiddenFiles) {
            Text(Localized.Document.showHiddenFiles)
          }
          .onChange(of: panelObserver.showsHiddenFiles) {
            AppPreferences.General.showHiddenFiles = panelObserver.showsHiddenFiles
            onValueChange(.showHiddenFiles(value: panelObserver.showsHiddenFiles))
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
  }
}
