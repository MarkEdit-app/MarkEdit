//
//  StatisticsLocalizable.swift
//
//  Created by cyan on 8/25/23.
//

import Foundation

public struct StatisticsLocalizable {
  let mainTitle: String
  let characters: String
  let words: String
  let sentences: String
  let paragraphs: String
  let fileSize: String
  let readTime: String

  public init(
    mainTitle: String,
    characters: String,
    words: String,
    sentences: String,
    paragraphs: String,
    fileSize: String,
    readTime: String
  ) {
    self.mainTitle = mainTitle
    self.characters = characters
    self.words = words
    self.sentences = sentences
    self.paragraphs = paragraphs
    self.fileSize = fileSize
    self.readTime = readTime
  }
}
