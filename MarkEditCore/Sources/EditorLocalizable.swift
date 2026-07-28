//
//  EditorLocalizable.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation

public struct EditorLocalizable: Encodable {
  let controlCharacter: String
  let foldedLines: String
  let unfoldedLines: String
  let foldedCode: String
  let unfold: String
  let foldLine: String
  let unfoldLine: String
  let previewButtonTitle: String
  let cmdClickToFollow: String
  let cmdClickToToggleTodo: String

  public init(
    controlCharacter: String,
    foldedLines: String,
    unfoldedLines: String,
    foldedCode: String,
    unfold: String,
    foldLine: String,
    unfoldLine: String,
    previewButtonTitle: String,
    cmdClickToFollow: String,
    cmdClickToToggleTodo: String
  ) {
    self.controlCharacter = controlCharacter
    self.foldedLines = foldedLines
    self.unfoldedLines = unfoldedLines
    self.foldedCode = foldedCode
    self.unfold = unfold
    self.foldLine = foldLine
    self.unfoldLine = unfoldLine
    self.previewButtonTitle = previewButtonTitle
    self.cmdClickToFollow = cmdClickToFollow
    self.cmdClickToToggleTodo = cmdClickToToggleTodo
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(controlCharacter, forKey: "controlCharacter")
    try container.encode(foldedLines, forKey: "foldedLines")
    try container.encode(unfoldedLines, forKey: "unfoldedLines")
    try container.encode(foldedCode, forKey: "foldedCode")
    try container.encode(unfold, forKey: "unfold")
    try container.encode(foldLine, forKey: "foldLine")
    try container.encode(unfoldLine, forKey: "unfoldLine")
    try container.encode(previewButtonTitle, forKey: "previewButtonTitle")
    try container.encode(cmdClickToFollow, forKey: "cmdClickToFollow")
    try container.encode(cmdClickToToggleTodo, forKey: "cmdClickToToggleTodo")
  }
}
