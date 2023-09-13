//
//  IntentError.swift
//  MarkEditMac
//
//  Created by cyan on 3/10/23.
//

import Foundation

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
  case missingDocument

  var localizedStringResource: LocalizedStringResource {
    switch self {
    case .missingDocument: return "Missing active document to proceed."
    }
  }
}
