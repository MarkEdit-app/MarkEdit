//
//  SettingsForm.swift
//
//  Created by cyan on 1/27/23.
//

import SwiftUI

/**
 Lightweight form builder for SwiftUI.
 */
public struct SettingsForm: View {
  // Generally speaking, we should avoid AnyView,
  // but here we wanted to erase the type so badly.
  public typealias TypedView = AnyView

  @resultBuilder
  public enum Builder {
    public static func buildBlock(_ sections: any View...) -> [TypedView] {
      sections.map { TypedView($0) }
    }
  }

  private let builder: () -> [TypedView]

  public init(@Builder builder: @escaping () -> [TypedView]) {
    self.builder = builder
  }

  public var body: some View {
    let sections = builder()
    Form {
      ForEach(0..<sections.count, id: \.self) { index in
        sections[index]
        VStack {}.padding(.bottom, index < sections.count - 1 ? 12 : 0)
      }
    }
    .fixedSize()
    .padding(20)
  }
}
