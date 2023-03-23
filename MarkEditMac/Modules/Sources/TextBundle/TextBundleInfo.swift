//
//  TextBundleInfo.swift
//
//  Created by cyan on 3/23/23.
//

import Foundation

/**
 https://textbundle.org/spec/
 */
public struct TextBundleInfo: Codable {
  public let version: UInt
  public let type: String
  public let transient: Bool
  public let creatorIdentifier: String
}
