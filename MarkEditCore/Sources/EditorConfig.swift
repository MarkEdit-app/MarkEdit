//
//  EditorConfig.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation

public struct EditorConfig: Encodable {
  let text: String
  let theme: String
  let fontFace: WebFontFace
  let fontSize: Double
  let showLineNumbers: Bool
  let showActiveLineIndicator: Bool
  let invisiblesBehavior: EditorInvisiblesBehavior
  let readOnlyMode: Bool
  let typewriterMode: Bool
  let focusMode: Bool
  let lineWrapping: Bool
  let lineHeight: Double
  let suggestWhileTyping: Bool
  let standardDirectories: [String: String]
  let defaultLineBreak: String?
  let tabKeyBehavior: Int?
  let indentUnit: String?
  let localizable: EditorLocalizable?
  let autoCharacterPairs: Bool
  let indentBehavior: EditorIndentBehavior
  let headerFontSizeDiffs: [Double]?
  let visibleWhitespaceCharacter: String?
  let visibleLineBreakCharacter: String?
  let searchNormalizers: [String: String]?

  public init(
    text: String,
    theme: String,
    fontFace: WebFontFace,
    fontSize: Double,
    showLineNumbers: Bool,
    showActiveLineIndicator: Bool,
    invisiblesBehavior: EditorInvisiblesBehavior,
    readOnlyMode: Bool,
    typewriterMode: Bool,
    focusMode: Bool,
    lineWrapping: Bool,
    lineHeight: Double,
    suggestWhileTyping: Bool,
    standardDirectories: [String: String],
    defaultLineBreak: String?,
    tabKeyBehavior: Int?,
    indentUnit: String?,
    localizable: EditorLocalizable?,
    autoCharacterPairs: Bool,
    indentBehavior: EditorIndentBehavior,
    headerFontSizeDiffs: [Double]?,
    visibleWhitespaceCharacter: String?,
    visibleLineBreakCharacter: String?,
    searchNormalizers: [String: String]?
  ) {
    self.text = text
    self.theme = theme
    self.fontFace = fontFace
    self.fontSize = fontSize
    self.showLineNumbers = showLineNumbers
    self.showActiveLineIndicator = showActiveLineIndicator
    self.invisiblesBehavior = invisiblesBehavior
    self.readOnlyMode = readOnlyMode
    self.typewriterMode = typewriterMode
    self.focusMode = focusMode
    self.lineWrapping = lineWrapping
    self.lineHeight = lineHeight
    self.suggestWhileTyping = suggestWhileTyping
    self.standardDirectories = standardDirectories
    self.defaultLineBreak = defaultLineBreak
    self.tabKeyBehavior = tabKeyBehavior
    self.indentUnit = indentUnit
    self.localizable = localizable
    self.autoCharacterPairs = autoCharacterPairs
    self.indentBehavior = indentBehavior
    self.headerFontSizeDiffs = headerFontSizeDiffs
    self.visibleWhitespaceCharacter = visibleWhitespaceCharacter
    self.visibleLineBreakCharacter = visibleLineBreakCharacter
    self.searchNormalizers = searchNormalizers
  }
}
