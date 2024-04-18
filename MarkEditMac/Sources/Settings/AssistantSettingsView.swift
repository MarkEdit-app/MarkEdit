//
//  AssistantSettingsView.swift
//  MarkEditMac
//
//  Created by cyan on 3/5/23.
//

import SwiftUI
import SettingsUI
import WebKit
import MarkEditKit

@MainActor
struct AssistantSettingsView: View {
  @State private var insertFinalNewline = AppPreferences.Assistant.insertFinalNewline
  @State private var trimTrailingWhitespace = AppPreferences.Assistant.trimTrailingWhitespace
  @State private var wordsInDocument = AppPreferences.Assistant.wordsInDocument
  @State private var standardWords = AppPreferences.Assistant.standardWords
  @State private var guessedWords = AppPreferences.Assistant.guessedWords
  @State private var inlinePredictions = AppPreferences.Assistant.inlinePredictions
  @State private var suggestWhileTyping = AppPreferences.Assistant.suggestWhileTyping
  private let supportsInlinePredictions = WKWebViewConfiguration().supportsInlinePredictions

  var body: some View {
    SettingsForm {
      Section {
        VStack(alignment: .leading) {
          Toggle(isOn: $insertFinalNewline) {
            Text(Localized.Settings.insertFinalNewline)
          }
          .onChange(of: insertFinalNewline) {
            AppPreferences.Assistant.insertFinalNewline = $0
          }

          Toggle(isOn: $trimTrailingWhitespace) {
            Text(Localized.Settings.trimTrailingWhitespace)
          }
          .onChange(of: trimTrailingWhitespace) {
            AppPreferences.Assistant.trimTrailingWhitespace = $0
          }

          Text(Localized.Settings.fileFormattingHint)
            .formDescription()
        }
        .formLabel(alignment: .top, Localized.Settings.formatFiles)
      }

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
            .formDescription()
        }
        .formLabel(alignment: .top, Localized.Settings.completion)
      }

      Section {
        VStack(alignment: .leading) {
          if supportsInlinePredictions {
            Toggle(isOn: $inlinePredictions) {
              Text(Localized.Settings.inlinePredictions)
            }
            .onChange(of: inlinePredictions) {
              AppPreferences.Assistant.inlinePredictions = $0
            }
          }

          Toggle(isOn: $suggestWhileTyping) {
            Text(Localized.Settings.suggestWhileTyping)
          }
          .onChange(of: suggestWhileTyping) {
            AppPreferences.Assistant.suggestWhileTyping = $0
          }
        }
        .formLabel(alignment: .top, Localized.Settings.autocomplete)
      }
    }
  }
}
