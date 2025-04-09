//
//  View+Extension.swift
//
//  Created by cyan on 4/9/25.
//

import AppKit
import SwiftUI

extension View {
  var measuredSize: CGSize {
    let layoutWrapper = NSHostingController(rootView: self)
    layoutWrapper.view.layoutSubtreeIfNeeded()
    return layoutWrapper.view.fittingSize
  }
}
