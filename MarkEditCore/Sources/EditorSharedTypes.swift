//
//  SharedTypes.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation

public enum EditorInvisiblesBehavior: String, Codable {
  case never = "never"
  case selection = "selection"
  case trailing = "trailing"
  case always = "always"
}

public struct TextTokenizeAnchor: Codable {
  public var text: String
  public var pos: Int
  public var offset: Int

  public init(text: String, pos: Int, offset: Int) {
    self.text = text
    self.pos = pos
    self.offset = offset
  }
}
