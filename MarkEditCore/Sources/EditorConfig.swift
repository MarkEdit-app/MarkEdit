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
  let runtimeInfo: RuntimeInfo?
  let defaultLineBreak: String?
  let tabKeyBehavior: Int?
  let indentUnit: String?
  let localizable: EditorLocalizable?
  let autoCharacterPairs: Bool
  let indentBehavior: EditorIndentBehavior
  let undoGroupingInterval: Double?
  let headerFontSizeDiffs: [Double]?
  let visibleWhitespaceCharacter: String?
  let visibleLineBreakCharacter: String?
  let searchNormalizers: [String: String]?

  public init(
    host: EditorHost,
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
    runtimeInfo: RuntimeInfo?,
    defaultLineBreak: String?,
    tabKeyBehavior: Int?,
    indentUnit: String?,
    localizable: EditorLocalizable?,
    autoCharacterPairs: Bool,
    indentBehavior: EditorIndentBehavior,
    undoGroupingInterval: Double?,
    headerFontSizeDiffs: [Double]?,
    visibleWhitespaceCharacter: String?,
    visibleLineBreakCharacter: String?,
    searchNormalizers: [String: String]?
  ) {
    self.host = host
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
    self.runtimeInfo = runtimeInfo
    self.defaultLineBreak = defaultLineBreak
    self.tabKeyBehavior = tabKeyBehavior
    self.indentUnit = indentUnit
    self.localizable = localizable
    self.autoCharacterPairs = autoCharacterPairs
    self.indentBehavior = indentBehavior
    self.undoGroupingInterval = undoGroupingInterval
    self.headerFontSizeDiffs = headerFontSizeDiffs
    self.visibleWhitespaceCharacter = visibleWhitespaceCharacter
    self.visibleLineBreakCharacter = visibleLineBreakCharacter
    self.searchNormalizers = searchNormalizers
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(host, forKey: "host")
    try container.encode(text, forKey: "text")
    try container.encode(theme, forKey: "theme")
    try container.encode(fontFace, forKey: "fontFace")
    try container.encode(fontSize, forKey: "fontSize")
    try container.encode(showLineNumbers, forKey: "showLineNumbers")
    try container.encode(showActiveLineIndicator, forKey: "showActiveLineIndicator")
    try container.encode(invisiblesBehavior, forKey: "invisiblesBehavior")
    try container.encode(readOnlyMode, forKey: "readOnlyMode")
    try container.encode(typewriterMode, forKey: "typewriterMode")
    try container.encode(focusMode, forKey: "focusMode")
    try container.encode(lineWrapping, forKey: "lineWrapping")
    try container.encode(lineHeight, forKey: "lineHeight")
    try container.encode(suggestWhileTyping, forKey: "suggestWhileTyping")
    try container.encode(standardDirectories, forKey: "standardDirectories")
    try container.encode(runtimeInfo, forKey: "runtimeInfo")
    try container.encode(defaultLineBreak, forKey: "defaultLineBreak")
    try container.encode(tabKeyBehavior, forKey: "tabKeyBehavior")
    try container.encode(indentUnit, forKey: "indentUnit")
    try container.encode(localizable, forKey: "localizable")
    try container.encode(autoCharacterPairs, forKey: "autoCharacterPairs")
    try container.encode(indentBehavior, forKey: "indentBehavior")
    try container.encode(undoGroupingInterval, forKey: "undoGroupingInterval")
    try container.encode(headerFontSizeDiffs, forKey: "headerFontSizeDiffs")
    try container.encode(visibleWhitespaceCharacter, forKey: "visibleWhitespaceCharacter")
    try container.encode(visibleLineBreakCharacter, forKey: "visibleLineBreakCharacter")
    try container.encode(searchNormalizers, forKey: "searchNormalizers")
  }
}
