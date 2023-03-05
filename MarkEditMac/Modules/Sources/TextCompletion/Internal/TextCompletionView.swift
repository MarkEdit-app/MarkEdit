//
//  TextCompletionView.swift
//
//  Created by cyan on 3/3/23.
//

import AppKit
import SwiftUI

struct TextCompletionView: View {
  @ObservedObject var state: TextCompletionState
  let localizable: TextCompletionLocalizable
  let commitCompletion: () -> Void

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
              .frame(
                maxWidth: .infinity,
                idealHeight: UIConstants.itemHeight,
                alignment: .leading
              )
              .accessibilityHint(index == state.selectedIndex ? localizable.selectedHint : "")
              .contentShape(Rectangle())
              .simultaneousGesture(
                DragGesture(minimumDistance: 0).onChanged { _ in
                  state.selectedIndex = index
                }
                .onEnded {
                  let bounds = CGRect(
                    x: 0,
                    y: 0,
                    width: UIConstants.itemWidth,
                    height: UIConstants.itemHeight
                  )

                  if bounds.contains($0.location) {
                    commitCompletion()
                  }
                }
              )
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
