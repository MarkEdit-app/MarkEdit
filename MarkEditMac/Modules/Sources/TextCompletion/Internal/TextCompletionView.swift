//
//  TextCompletionView.swift
//
//  Created by cyan on 3/3/23.
//

import AppKit
import SwiftUI

struct TextCompletionView: View {
  @ObservedObject private var state: TextCompletionState
  private let localizable: TextCompletionLocalizable
  private let commitCompletion: () -> Void

  private enum Constants {
    static let fontSize: Double = 14
    static let itemWidth: Double = 112
    static let itemHeight: Double = 24
    static let itemPadding: Double = 4
  }

  init(
    state: TextCompletionState,
    localizable: TextCompletionLocalizable,
    commitCompletion: @escaping () -> Void
  ) {
    self.state = state
    self.localizable = localizable
    self.commitCompletion = commitCompletion
  }

  var body: some View {
    VStack {
      ScrollViewReader { scrollView in
        ScrollView(showsIndicators: false) {
          LazyVStack(spacing: 0) {
            ForEach(0..<state.items.count, id: \.self) { index in
              ZStack(alignment: .leading) {
                if index == state.selectedIndex {
                  Color.accent.clipShape(RoundedRectangle(cornerRadius: 3.5, style: .continuous))
                }

                Text(state.items[index])
                  .font(.system(size: Constants.fontSize))
                  .foregroundColor(index == state.selectedIndex ? .white : .label)
                  .padding([.leading, .trailing], Constants.itemPadding)
              }
              .frame(
                maxWidth: .infinity,
                idealHeight: Constants.itemHeight,
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
                    width: Constants.itemWidth,
                    height: Constants.itemHeight
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
    .padding(Constants.itemPadding)
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

  static func panelSize(itemCount: Int) -> CGSize {
    CGSize(
      width: Constants.itemWidth + 2 * Constants.itemPadding,
      height: Double(min(8, itemCount)) * Constants.itemHeight + 2 * Constants.itemPadding
    )
  }
}
