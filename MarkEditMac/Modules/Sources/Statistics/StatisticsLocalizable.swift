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
  let comments: String
  let readTime: String
  let fileSize: String

  public init(
    mainTitle: String,
    characters: String,
    words: String,
    sentences: String,
    paragraphs: String,
    comments: String,
    readTime: String,
    fileSize: String
  ) {
    self.mainTitle = mainTitle
    self.characters = characters
    self.words = words
    self.sentences = sentences
    self.paragraphs = paragraphs
    self.comments = comments
    self.readTime = readTime
    self.fileSize = fileSize
  }
}
