//
//  SharedTypes.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation

/// Font face attributes to control the font styles.
public struct WebFontFace: Codable {
  public var family: String
  public var weight: String?
  public var style: String?

  public init(family: String, weight: String?, style: String?) {
    self.family = family
    self.weight = weight
    self.style = style
  }
}

public enum EditorInvisiblesBehavior: String, Codable {
  case never = "never"
  case selection = "selection"
  case trailing = "trailing"
  case always = "always"
}

/// "CGRect-fashion" rect.
public struct JSRect: Codable {
  public var x: Double
  public var y: Double
  public var width: Double
  public var height: Double

  public init(x: Double, y: Double, width: Double, height: Double) {
    self.x = x
    self.y = y
    self.width = width
    self.height = height
  }
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
