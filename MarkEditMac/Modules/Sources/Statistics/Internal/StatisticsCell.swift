//
//  StatisticsCell.swift
//
//  Created by cyan on 8/26/23.
//

import SwiftUI

struct StatisticsCell: View {
  let iconName: String
  let titleText: String
  let valueText: String

  var body: some View {
    HStack(alignment: .center, spacing: 4) {
      Image(systemName: iconName)
        .frame(width: 28)
        .foregroundColor(.gray)
      Text(titleText)
        .fixedSize()
      Text(valueText)
        .fontWeight(.semibold)
        .lineLimit(1)
        .frame(maxWidth: .infinity, alignment: .trailing)
    }
    .frame(height: 32)
    Divider()
  }
}
