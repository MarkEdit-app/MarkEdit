//
//  SharedTypes.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation

public enum EditorHost: String, Codable {
  case mainApp = "mainApp"
  case quicklook = "quicklook"
}

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

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    family = try container.value("family")
    weight = try container.value("weight")
    style = try container.value("style")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(family, forKey: "family")
    try container.encode(weight, forKey: "weight")
    try container.encode(style, forKey: "style")
  }
}

public enum EditorInvisiblesBehavior: String, Codable {
  case never = "never"
  case selection = "selection"
  case trailing = "trailing"
  case always = "always"
}

public struct RuntimeInfo: Codable {
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

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    appVersion = try container.value("appVersion")
    appBuild = try container.value("appBuild")
    osVersion = try container.value("osVersion")
    webkitVersion = try container.value("webkitVersion")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(appVersion, forKey: "appVersion")
    try container.encode(appBuild, forKey: "appBuild")
    try container.encode(osVersion, forKey: "osVersion")
    try container.encode(webkitVersion, forKey: "webkitVersion")
  }
}

public enum EditorIndentBehavior: String, Codable {
  case never = "never"
  case paragraph = "paragraph"
  case line = "line"
}

public struct SelectionRange: Codable {
  public var anchor: Int
  public var head: Int

  public init(anchor: Int, head: Int) {
    self.anchor = anchor
    self.head = head
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    anchor = try container.value("anchor")
    head = try container.value("head")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(anchor, forKey: "anchor")
    try container.encode(head, forKey: "head")
  }
}

/// "CGRect-fashion" rect.
public struct WebRect: Codable {
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

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    x = try container.value("x")
    y = try container.value("y")
    width = try container.value("width")
    height = try container.value("height")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(x, forKey: "x")
    try container.encode(y, forKey: "y")
    try container.encode(width, forKey: "width")
    try container.encode(height, forKey: "height")
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

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    text = try container.value("text")
    pos = try container.value("pos")
    offset = try container.value("offset")
  }

  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: BridgeFieldKey.self)
    try container.encode(text, forKey: "text")
    try container.encode(pos, forKey: "pos")
    try container.encode(offset, forKey: "offset")
  }
}
