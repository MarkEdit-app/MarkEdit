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
  let fontFamily: String
  let fontSize: Double
  let showLineNumbers: Bool
  let showActiveLineIndicator: Bool
  let invisiblesBehavior: EditorInvisiblesBehavior
  let typewriterMode: Bool
  let focusMode: Bool
  let lineWrapping: Bool
  let lineHeight: Double
  let suggestWhileTyping: Bool
  let defaultLineBreak: String?
  let tabKeyBehavior: Int?
  let indentUnit: String?
  let localizable: EditorLocalizable?

  public init(
    text: String,
    theme: String,
    fontFamily: String,
    fontSize: Double,
    showLineNumbers: Bool,
    showActiveLineIndicator: Bool,
    invisiblesBehavior: EditorInvisiblesBehavior,
    typewriterMode: Bool,
    focusMode: Bool,
    lineWrapping: Bool,
    lineHeight: Double,
    suggestWhileTyping: Bool,
    defaultLineBreak: String?,
    tabKeyBehavior: Int?,
    indentUnit: String?,
    localizable: EditorLocalizable?
  ) {
    self.text = text
    self.theme = theme
    self.fontFamily = fontFamily
    self.fontSize = fontSize
    self.showLineNumbers = showLineNumbers
    self.showActiveLineIndicator = showActiveLineIndicator
    self.invisiblesBehavior = invisiblesBehavior
    self.typewriterMode = typewriterMode
    self.focusMode = focusMode
    self.lineWrapping = lineWrapping
    self.lineHeight = lineHeight
    self.suggestWhileTyping = suggestWhileTyping
    self.defaultLineBreak = defaultLineBreak
    self.tabKeyBehavior = tabKeyBehavior
    self.indentUnit = indentUnit
    self.localizable = localizable
  }
}
