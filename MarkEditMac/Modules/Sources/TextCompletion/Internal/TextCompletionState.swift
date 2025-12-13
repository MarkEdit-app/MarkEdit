//
//  TextCompletionState.swift
//
//  Created by cyan on 3/4/23.
//

import Observation

@Observable
final class TextCompletionState {
  var items = [String]()
  var query = ""
  var selectedIndex = 0
}
