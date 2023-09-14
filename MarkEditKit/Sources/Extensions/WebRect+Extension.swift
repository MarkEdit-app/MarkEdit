//
//  WebRect+Extension.swift
//
//  Created by cyan on 1/7/23.
//

import Foundation
import MarkEditCore

public extension WebRect {
  var cgRect: CGRect {
    CGRect(x: x, y: y, width: width, height: height)
  }
}
