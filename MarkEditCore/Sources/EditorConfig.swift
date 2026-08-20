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
  let host: EditorHost
  let text: String
  let fontFace: WebFontFace
  let invisiblesBehavior: EditorInvisiblesBehavior
  let tabKeyBehavior: Int?
  let localizable: EditorLocalizable?
  let autoCharacterPairs: Bool
  let indentBehavior: EditorIndentBehavior
  let undoGroupingInterval: Double?
  let headerFontSizeDiffs: [Double]?
  let visibleWhitespaceCharacter: String?
  let visibleLineBreakCharacter: String?
  let searchNormalizers: [String: String]?
  let theme: String
  let fontSize: Double
  let showLineNumbers: Bool
  let showActiveLineIndicator: Bool
  let readOnlyMode: Bool
  let typewriterMode: Bool
  let focusMode: Bool
  let lineWrapping: Bool
  let lineHeight: Double
  let suggestWhileTyping: Bool
  let standardDirectories: [String: String]
  let runtimeInfo: RuntimeInfo?
  let defaultLineBreak: String?
  let indentUnit: String?
  let smartQuotesEnabled: Bool

  public init(
    host: EditorHost,
    text: String,
    fontFace: WebFontFace,
    invisiblesBehavior: EditorInvisiblesBehavior,
    tabKeyBehavior: Int?,
    localizable: EditorLocalizable?,
    autoCharacterPairs: Bool,
    indentBehavior: EditorIndentBehavior,
    undoGroupingInterval: Double?,
    headerFontSizeDiffs: [Double]?,
    visibleWhitespaceCharacter: String?,
    visibleLineBreakCharacter: String?,
    searchNormalizers: [String: String]?,
    theme: String,
    fontSize: Double,
    showLineNumbers: Bool,
    showActiveLineIndicator: Bool,
    readOnlyMode: Bool,
    typewriterMode: Bool,
    focusMode: Bool,
    lineWrapping: Bool,
    lineHeight: Double,
    suggestWhileTyping: Bool,
    standardDirectories: [String: String],
    runtimeInfo: RuntimeInfo?,
    defaultLineBreak: String?,
    indentUnit: String?,
    smartQuotesEnabled: Bool
  ) {
    self.host = host
    self.text = text
    self.fontFace = fontFace
    self.invisiblesBehavior = invisiblesBehavior
    self.tabKeyBehavior = tabKeyBehavior
    self.localizable = localizable
    self.autoCharacterPairs = autoCharacterPairs
    self.indentBehavior = indentBehavior
    self.undoGroupingInterval = undoGroupingInterval
    self.headerFontSizeDiffs = headerFontSizeDiffs
    self.visibleWhitespaceCharacter = visibleWhitespaceCharacter
    self.visibleLineBreakCharacter = visibleLineBreakCharacter
    self.searchNormalizers = searchNormalizers
    self.theme = theme
    self.fontSize = fontSize
    self.showLineNumbers = showLineNumbers
    self.showActiveLineIndicator = showActiveLineIndicator
    self.readOnlyMode = readOnlyMode
    self.typewriterMode = typewriterMode
    self.focusMode = focusMode
    self.lineWrapping = lineWrapping
    self.lineHeight = lineHeight
    self.suggestWhileTyping = suggestWhileTyping
    self.standardDirectories = standardDirectories
    self.runtimeInfo = runtimeInfo
    self.defaultLineBreak = defaultLineBreak
    self.indentUnit = indentUnit
    self.smartQuotesEnabled = smartQuotesEnabled
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(host, forKey: "host")
    try container.encode(text, forKey: "text")
    try container.encode(fontFace, forKey: "fontFace")
    try container.encode(invisiblesBehavior, forKey: "invisiblesBehavior")
    try container.encode(tabKeyBehavior, forKey: "tabKeyBehavior")
    try container.encode(localizable, forKey: "localizable")
    try container.encode(autoCharacterPairs, forKey: "autoCharacterPairs")
    try container.encode(indentBehavior, forKey: "indentBehavior")
    try container.encode(undoGroupingInterval, forKey: "undoGroupingInterval")
    try container.encode(headerFontSizeDiffs, forKey: "headerFontSizeDiffs")
    try container.encode(visibleWhitespaceCharacter, forKey: "visibleWhitespaceCharacter")
    try container.encode(visibleLineBreakCharacter, forKey: "visibleLineBreakCharacter")
    try container.encode(searchNormalizers, forKey: "searchNormalizers")
    try container.encode(theme, forKey: "theme")
    try container.encode(fontSize, forKey: "fontSize")
    try container.encode(showLineNumbers, forKey: "showLineNumbers")
    try container.encode(showActiveLineIndicator, forKey: "showActiveLineIndicator")
    try container.encode(readOnlyMode, forKey: "readOnlyMode")
    try container.encode(typewriterMode, forKey: "typewriterMode")
    try container.encode(focusMode, forKey: "focusMode")
    try container.encode(lineWrapping, forKey: "lineWrapping")
    try container.encode(lineHeight, forKey: "lineHeight")
    try container.encode(suggestWhileTyping, forKey: "suggestWhileTyping")
    try container.encode(standardDirectories, forKey: "standardDirectories")
    try container.encode(runtimeInfo, forKey: "runtimeInfo")
    try container.encode(defaultLineBreak, forKey: "defaultLineBreak")
    try container.encode(indentUnit, forKey: "indentUnit")
    try container.encode(smartQuotesEnabled, forKey: "smartQuotesEnabled")
  }
}
