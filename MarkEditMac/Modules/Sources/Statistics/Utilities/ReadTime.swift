//
//  ReadTime.swift
//
//  Created by cyan on 8/26/23.
//

import Foundation

/**
 Utility to estimate time needed for reading.
 */
enum ReadTime {
  static func estimated(of numberOfWords: Int) -> String? {
    let seconds = ceil((Double(numberOfWords) / 225) * 60)
    let formatter = DateComponentsFormatter()

    formatter.unitsStyle = .short
    formatter.allowedUnits = [.hour, .minute, .second]
    formatter.zeroFormattingBehavior = .dropAll
    formatter.maximumUnitCount = 2

    return formatter.string(from: seconds)
  }
}
