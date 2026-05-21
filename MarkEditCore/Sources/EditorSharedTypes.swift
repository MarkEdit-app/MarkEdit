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
public struct WebFontFace: Codable, Equatable {
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

public struct RuntimeInfo: Codable, Equatable {
  /// Application version, such as `1.0`.
  public var appVersion: String
  /// Application build number, such as `100`.
  public var appBuild: String
  /// Operating system version, such as `15.0`.
  public var osVersion: String
  /// WebKit version, such as `620.1.16`.
  public var webkitVersion: String

  public init(appVersion: String, appBuild: String, osVersion: String, webkitVersion: String) {
    self.appVersion = appVersion
    self.appBuild = appBuild
    self.osVersion = osVersion
    self.webkitVersion = webkitVersion
  }
}

public enum EditorIndentBehavior: String, Codable {
  case never = "never"
  case paragraph = "paragraph"
  case line = "line"
}

public struct SelectionRange: Codable, Equatable {
  public var anchor: Int
  public var head: Int

  public init(anchor: Int, head: Int) {
    self.anchor = anchor
    self.head = head
  }
}

/// "CGRect-fashion" rect.
public struct WebRect: Codable, Equatable {
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

public struct TextTokenizeAnchor: Codable, Equatable {
  public var text: String
  public var pos: Int
  public var offset: Int

  public init(text: String, pos: Int, offset: Int) {
    self.text = text
    self.pos = pos
    self.offset = offset
  }
}
