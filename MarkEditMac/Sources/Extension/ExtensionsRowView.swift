//
//  ExtensionsRowView.swift
//  MarkEditMac
//
//  Created by cyan on 7/13/26.
//

import SwiftUI
import ExtensionCore
import SharedUI

/// A single extension's row: its metadata and action controls.
struct ExtensionsRowView: View {
  let model: ExtensionsModel
  let item: ExtensionsModel.Item

  var body: some View {
    // Read live state so the cell animates its own updates instead of being reloaded.
    let item = liveItem

    HStack(spacing: 10) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
          Image(systemName: item.category == .theme ? Icons.paintpalette : Icons.puzzlepieceExtension)
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)

          Text(item.name)
            .font(.title3)
            .fontWeight(.semibold)
            .lineLimit(1)

          if let updateVersion = item.updateVersion {
            Text(verbatim: "↑ \(updateVersion)")
              .font(.caption)
              .foregroundStyle(.tint)
              .accessibilityLabel(String(format: Localized.Extension.updateToFormat, updateVersion))
          }
        }

        if !item.details.isEmpty {
          Text(item.details)
            .font(.body)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
        }

        if item.category == .theme, let patterns = item.colorPatterns, !patterns.isEmpty {
          ThemePreview(patterns: patterns, showsBothSchemes: item.colorScheme == .both)
            .padding(.top, 4)
        }

        if !item.author.isEmpty || item.version != nil || item.homepage != nil {
          HStack(spacing: 5) {
            if let version = item.version {
              Text(verbatim: "v\(version)")
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            if !item.author.isEmpty {
              if item.version != nil {
                metadataDot
              }

              Text(item.author)
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            if let homepage = item.homepage {
              if item.version != nil || !item.author.isEmpty {
                metadataDot
              }

              Link(Localized.Extension.homepage, destination: homepage)
                .font(.callout)
                .fontWeight(.medium)
            }
          }
          .padding(.top, 12)
        }
      }

      Spacer()

      // Centered vertically on the cell
      trailingControl(item: item)
    }
    .padding(.vertical, 8)
  }
}

// MARK: - Private

private extension ExtensionsRowView {
  /// Live snapshot of this item, falling back to the initial value if it's no longer listed.
  var liveItem: ExtensionsModel.Item {
    model.liveItem(id: item.id) ?? item
  }

  /// Whether this item is running an install/update, so it shows a spinner instead of a button.
  var isItemBusy: Bool {
    model.busyItemID == item.id
  }

  func enabledBinding(for item: ExtensionsModel.Item) -> Binding<Bool> {
    Binding(
      get: { item.isEnabled },
      set: { model.setEnabled($0, for: item) }
    )
  }

  @ViewBuilder
  func trailingControl(item: ExtensionsModel.Item) -> some View {
    buttonControls(for: item)
      .opacity(isItemBusy ? 0 : 1)
      .allowsHitTesting(!isItemBusy)
      .overlay {
        SpinningRing()
          .opacity(isItemBusy ? 1 : 0)
          .allowsHitTesting(false)
      }
      .animation(.easeInOut(duration: 0.25), value: isItemBusy)
  }

  @ViewBuilder
  func buttonControls(for item: ExtensionsModel.Item) -> some View {
    if model.mode == .installed {
      HStack(spacing: 8) {
        updateButton(for: item)
        revealButton(for: item)

        PillButton(Localized.Extension.uninstall, style: .bordered) {
          Task {
            await model.uninstallExtension(item)
          }
        }

        Toggle(Localized.Extension.enabled, isOn: enabledBinding(for: item))
          .toggleStyle(.checkbox)
          .labelsHidden()
          .help(Localized.Extension.enabledTooltip)
      }
    } else if !item.isInstalled {
      PillButton(Localized.Extension.installButton, style: .prominent) {
        Task {
          await model.installExtension(item)
        }
      }
    } else if item.updateVersion != nil {
      HStack(spacing: 8) {
        updateButton(for: item)
        revealButton(for: item)
      }
    } else {
      revealButton(for: item)
    }
  }

  @ViewBuilder
  func updateButton(for item: ExtensionsModel.Item) -> some View {
    if let updateVersion = item.updateVersion {
      PillButton(String(format: Localized.Extension.updateToFormat, updateVersion), style: .bordered) {
        Task {
          await model.updateExtension(item)
        }
      }
    }
  }

  func revealButton(for item: ExtensionsModel.Item) -> some View {
    PillButton(Localized.Extension.reveal, style: .bordered) {
      model.revealScriptFile(item)
    }
  }

  var metadataDot: some View {
    Text(verbatim: "·")
      .bold()
      .foregroundStyle(.secondary)
      .accessibilityHidden(true)
  }
}
