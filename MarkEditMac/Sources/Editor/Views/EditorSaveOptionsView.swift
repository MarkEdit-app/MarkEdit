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
  @State private var filenameExtension = AppPreferences.General.newFilenameExtension
  @State private var textEncoding = AppPreferences.General.defaultTextEncoding

  private let extensionChanged: ((NewFilenameExtension) -> Void)
  private let encodingChanged: ((EditorTextEncoding) -> Void)

  static func wrapper(for panel: NSSavePanel, encodingChanged: @escaping (EditorTextEncoding) -> Void) -> NSView {
    NSHostingView(rootView: Self(
      extensionChanged: {
        let allowsOtherFileTypes = panel.allowsOtherFileTypes == true
        panel.allowsOtherFileTypes = false
        panel.allowedContentTypes = [$0.uniformType]

        // Must turn this off temporarily to enforce the file type
        DispatchQueue.main.async {
          panel.allowsOtherFileTypes = allowsOtherFileTypes
        }
      },
      encodingChanged: encodingChanged
    ))
  }

  var body: some View {
    SettingsForm(padding: 8) {
      Section {
        Picker(Localized.Document.filenameExtension, selection: $filenameExtension) {
          ForEach(NewFilenameExtension.allCases, id: \.self) {
            Text($0.rawValue).tag($0)
          }
        }
        .onChange(of: filenameExtension) {
          extensionChanged(filenameExtension)
        }
        .formMenuPicker(minWidth: 120)

        Picker(Localized.Document.textEncoding, selection: $textEncoding) {
          ForEach(EditorTextEncoding.allCases, id: \.self) {
            Text($0.description)

            if EditorTextEncoding.groupingCases.contains($0) {
              Divider()
            }
          }
        }
        .onChange(of: textEncoding) {
          encodingChanged(textEncoding)
        }
        .formMenuPicker(minWidth: 120)
      }
    }
    .frame(maxWidth: .infinity)
  }
}
