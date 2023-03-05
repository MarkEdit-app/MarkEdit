//
//  AssistantSettingsView.swift
//  MarkEditMac
//
//  Created by cyan on 3/5/23.
//

import SwiftUI
import SettingsUI

struct AssistantSettingsView: View {
  @State private var wordsInDocument = AppPreferences.Assistant.wordsInDocument
  @State private var standardWords = AppPreferences.Assistant.standardWords
  @State private var guessedWords = AppPreferences.Assistant.guessedWords
  @State private var suggestWhileTyping = AppPreferences.Assistant.suggestWhileTyping

  var body: some View {
    SettingsForm {
      Section {
        VStack(alignment: .leading) {
          Toggle(isOn: $wordsInDocument) {
            Text(Localized.Settings.wordsInDocument)
          }
          .onChange(of: wordsInDocument) {
            AppPreferences.Assistant.wordsInDocument = $0
          }

          Toggle(isOn: $standardWords) {
            Text(Localized.Settings.standardWords)
          }
          .onChange(of: standardWords) {
            AppPreferences.Assistant.standardWords = $0
          }

          Toggle(isOn: $guessedWords) {
            Text(Localized.Settings.guessedWords)
          }
          .onChange(of: guessedWords) {
            AppPreferences.Assistant.guessedWords = $0
          }

          Text(Localized.Settings.completionHint)
            .font(.system(size: 12))
            .foregroundStyle(.secondary)
        }
        .formLabel(alignment: .top, Localized.Settings.completion)
      }

      Section {
        Toggle(isOn: $suggestWhileTyping) {
          Text(Localized.Settings.suggestWhileTyping)
        }
        .onChange(of: suggestWhileTyping) {
          AppPreferences.Assistant.suggestWhileTyping = $0
        }
        .formLabel(alignment: .top, Localized.Settings.autocomplete)
      }
    }
  }
}
