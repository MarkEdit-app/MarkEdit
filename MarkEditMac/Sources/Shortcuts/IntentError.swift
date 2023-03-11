//
//  IntentError.swift
//  MarkEditMac
//
//  Created by cyan on 3/10/23.
//

import Foundation

@available(macOS 13.0, *)
enum IntentError: Error, CustomLocalizedStringResourceConvertible {
  case missingDocument

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .missingDocument: return "Missing active document to proceed."
    }
  }
}
