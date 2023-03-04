//
//  TextCompletionView.swift
//
//  Created by cyan on 3/3/23.
//

import AppKit
import SwiftUI

struct TextCompletionView: View {
  let localizable: TextCompletionLocalizable
  @ObservedObject var state: TextCompletionState

  var body: some View {
    VStack {
      ScrollViewReader { scrollView in
        ScrollView(showsIndicators: false) {
          LazyVStack(spacing: 0) {
            ForEach(0..<state.items.count, id: \.self) { index in
              ZStack(alignment: .leading) {
                if index == state.selectedIndex {
                  Color.blue.clipShape(RoundedRectangle(cornerRadius: 4, style: .continuous))
                }

                Text(state.items[index])
                  .font(.system(size: UIConstants.fontSize))
                  .foregroundColor(index == state.selectedIndex ? .white : .label)
                  .padding([.leading, .trailing], UIConstants.itemPadding)
              }
              .id(index)
              .frame(
                maxWidth: .infinity,
                idealHeight: UIConstants.itemHeight,
                alignment: .leading
              )
              .accessibilityHint(index == state.selectedIndex ? localizable.selectedHint : "")
            }
          }
        }
        .onChange(of: state.selectedIndex) { newIndex in
          scrollView.scrollTo(newIndex)
        }
      }
    }
    .padding(UIConstants.itemPadding)
    .onHover { isHovered in
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.02) {
        if isHovered {
          NSCursor.arrow.push()
        } else {
          NSCursor.pop()
        }
      }
    }
  }
}
