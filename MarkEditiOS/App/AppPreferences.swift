//
//  AppPreferences.swift
//  MarkEditiOS
//
//  Lightweight UserDefaults wrapper for iOS editor settings.
//

import UIKit
import MarkEditCore

enum AppPreferences {
  enum Editor {
    static var theme: String {
      get { UserDefaults.standard.string(forKey: "ios.editor.theme") ?? defaultTheme }
      set { UserDefaults.standard.set(newValue, forKey: "ios.editor.theme") }
    }

    static var fontSize: Double {
      get {
        let value = UserDefaults.standard.double(forKey: "ios.editor.fontSize")
        return value > 0 ? value : 15
      }
      set { UserDefaults.standard.set(newValue, forKey: "ios.editor.fontSize") }
    }

    static var lineWrapping: Bool {
      get { UserDefaults.standard.object(forKey: "ios.editor.lineWrapping") as? Bool ?? true }
      set { UserDefaults.standard.set(newValue, forKey: "ios.editor.lineWrapping") }
    }

    static var showLineNumbers: Bool {
      get { UserDefaults.standard.object(forKey: "ios.editor.showLineNumbers") as? Bool ?? false }
      set { UserDefaults.standard.set(newValue, forKey: "ios.editor.showLineNumbers") }
    }

    // GitHub Light for light mode, GitHub Dark for dark mode
    private static var defaultTheme: String {
      switch UITraitCollection.current.userInterfaceStyle {
      case .dark: return "GitHub Dark"
      default: return "GitHub Light"
      }
    }
  }
}
