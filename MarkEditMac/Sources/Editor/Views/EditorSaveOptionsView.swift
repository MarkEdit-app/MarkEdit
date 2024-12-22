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
 Accessory view used in NSSavePanel to provide additional options.
 */
struct EditorSaveOptionsView: View {
  struct Options: OptionSet {
    let rawValue: Int
    static let fileExtension = Self(rawValue: 1 << 0)
    static let textEncoding = Self(rawValue: 1 << 1)
    static let all: Self = [.fileExtension, .textEncoding]
  }

  enum Result {
    case fileExtension(value: NewFilenameExtension)
    case textEncoding(value: EditorTextEncoding)
  }

  @State private var filenameExtension = AppPreferences.General.newFilenameExtension
  @State private var textEncoding = AppPreferences.General.defaultTextEncoding

  private let options: Options
  private let onValueChange: ((Result) -> Void)

  static func wrapper(for options: Options, onValueChange: @escaping ((Result) -> Void)) -> NSView {
    NSHostingView(rootView: Self(options: options, onValueChange: onValueChange))
  }

  var body: some View {
    SettingsForm(padding: 8) {
      Section {
        if options.contains(.fileExtension) {
          Picker(Localized.Document.filenameExtension, selection: $filenameExtension) {
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
      }
    }
    .frame(maxWidth: .infinity)
  }
}
