//
//  SettingsViewController.swift
//  MarkEditiOS
//
//  Minimal settings screen: theme, font size, line wrap, line numbers.
//  Changes are persisted with UserDefaults and applied to the editor on dismiss.
//

import UIKit
import SwiftUI

final class SettingsViewController: UIViewController {
  var onDismiss: (() -> Void)?

  override func viewDidLoad() {
    super.viewDidLoad()
    title = "Settings"
    view.backgroundColor = .systemGroupedBackground

    navigationItem.rightBarButtonItem = UIBarButtonItem(
      barButtonSystemItem: .done,
      target: self,
      action: #selector(doneTapped)
    )

    // Embed SwiftUI settings form
    let settingsView = SettingsView()
    let hostingController = UIHostingController(rootView: settingsView)
    addChild(hostingController)
    hostingController.view.translatesAutoresizingMaskIntoConstraints = false
    view.addSubview(hostingController.view)
    NSLayoutConstraint.activate([
      hostingController.view.topAnchor.constraint(equalTo: view.topAnchor),
      hostingController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
      hostingController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
      hostingController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
    ])
    hostingController.didMove(toParent: self)
  }

  @objc private func doneTapped() {
    dismiss(animated: true) { [weak self] in
      self?.onDismiss?()
    }
  }
}

// MARK: - SwiftUI Settings Form

private struct SettingsView: View {
  @AppStorage("ios.editor.fontSize")
  private var fontSize: Double = 15

  @AppStorage("ios.editor.lineWrapping")
  private var lineWrapping: Bool = true

  @AppStorage("ios.editor.showLineNumbers")
  private var showLineNumbers: Bool = false

  private let themes = [
    "GitHub Light",
    "GitHub Dark",
    "One Dark",
    "Solarized Light",
    "Solarized Dark",
    "Dracula",
    "Nord",
    "Gruvbox Dark",
  ]

  @AppStorage("ios.editor.theme")
  private var selectedTheme: String = "GitHub Light"

  var body: some View {
    Form {
      Section("Appearance") {
        Picker("Theme", selection: $selectedTheme) {
          ForEach(themes, id: \.self) { theme in
            Text(theme).tag(theme)
          }
        }
      }

      Section("Typography") {
        VStack(alignment: .leading, spacing: 4) {
          HStack {
            Text("Font Size")
            Spacer()
            Text("\(Int(fontSize)) pt")
              .foregroundColor(.secondary)
              .monospacedDigit()
          }
          Slider(value: $fontSize, in: 10...28, step: 1)
        }
        .padding(.vertical, 4)
      }

      Section("Editor") {
        Toggle("Line Wrap", isOn: $lineWrapping)
        Toggle("Show Line Numbers", isOn: $showLineNumbers)
      }
    }
  }
}
