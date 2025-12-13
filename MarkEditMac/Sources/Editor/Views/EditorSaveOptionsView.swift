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
 Observable object to synchronize showHiddenFiles state with external changes.
 */
final class ShowHiddenFilesObserver: ObservableObject {
  @Published var value: Bool
  
  init(initialValue: Bool) {
    self.value = initialValue
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
  @ObservedObject private var showHiddenFilesObserver: ShowHiddenFilesObserver

  private let options: Options
  private let onValueChange: ((Result) -> Void)
  
  init(options: Options, showHiddenFilesObserver: ShowHiddenFilesObserver? = nil, onValueChange: @escaping ((Result) -> Void)) {
    self.options = options
    self.onValueChange = onValueChange
    self.showHiddenFilesObserver = showHiddenFilesObserver ?? ShowHiddenFilesObserver(initialValue: AppPreferences.General.showHiddenFiles)
  }

  static func wrapper(for options: Options, showHiddenFilesObserver: ShowHiddenFilesObserver? = nil, onValueChange: @escaping ((Result) -> Void)) -> NSView {
    NSHostingView(rootView: Self(options: options, showHiddenFilesObserver: showHiddenFilesObserver, onValueChange: onValueChange))
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
          Toggle(isOn: $showHiddenFilesObserver.value) {
            Text(Localized.Document.showHiddenFiles)
          }
          .onChange(of: showHiddenFilesObserver.value) {
            onValueChange(.showHiddenFiles(value: showHiddenFilesObserver.value))
          }
        }
      }
    }
    .frame(maxWidth: .infinity)
  }
}
