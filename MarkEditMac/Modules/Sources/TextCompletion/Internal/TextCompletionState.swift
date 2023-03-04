//
//  TextCompletionState.swift
//
//  Created by cyan on 3/4/23.
//

import Combine

final class TextCompletionState: ObservableObject {
  @Published var items = [String]()
  @Published var selectedIndex = 0
}
