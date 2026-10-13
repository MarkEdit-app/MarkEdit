//
//  QuickSearchItem.swift
//
//  Created by cyan on 10/11/26.
//

import AppKit

public struct QuickSearchItem: Equatable {
  public let id: String
  public let title: String
  public let subtitle: String
  public let iconName: String
  public let iconColor: NSColor
  public let highlightedRanges: [NSRange]

  public init(
    id: String,
    title: String,
    subtitle: String,
    iconName: String,
    iconColor: NSColor = .systemBlue,
    highlightedRanges: [NSRange] = []
  ) {
    self.id = id
    self.title = title
    self.subtitle = subtitle
    self.iconName = iconName
    self.iconColor = iconColor
    self.highlightedRanges = highlightedRanges
  }
}

@MainActor
public struct QuickSearchResultsConfiguration {
  let filterMenu: NSMenu?
  let onQueryChange: (String) -> Void
  let onActivate: (String) -> Void
  let onDismiss: () -> Void

  public init(
    filterMenu: NSMenu? = nil,
    onQueryChange: @escaping (String) -> Void,
    onActivate: @escaping (String) -> Void,
    onDismiss: @escaping () -> Void
  ) {
    self.filterMenu = filterMenu
    self.onQueryChange = onQueryChange
    self.onActivate = onActivate
    self.onDismiss = onDismiss
  }
}
