//
//  ExtensionsRowView.swift
//  MarkEditMac
//
//  Created by cyan on 7/13/26.
//

import SwiftUI
import AppKitExtensions
import ExtensionCore
import SharedUI

/// A single extension's row: its metadata and action controls.
struct ExtensionsRowView: View {
  let model: ExtensionsModel
  let item: ExtensionsModel.Item
  let rowMargin: Double

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

          if item.isOfficial {
            Image(systemName: Icons.checkmarkSeal)
              .foregroundStyle(.orange)
              .help(Localized.Extension.official)
              .accessibilityLabel(Localized.Extension.official)
          }

          if let updateVersion = item.updateVersion {
            updateBadge(version: updateVersion, url: item.latestReleaseURL)
              .transition(.opacity.combined(with: .scale))
          }
        }
        // Only animate the row being upgraded, not tab switches.
        .animation(isItemBusy ? .easeInOut(duration: 0.25) : nil, value: item.updateVersion)

        if !item.details.isEmpty {
          Text(item.details)
            .font(.body)
            .foregroundStyle(.secondary)
            // Keep the description on one line; users can widen the window to read more.
            .lineLimit(1)
            .truncationMode(.tail)
        }

        if item.category == .theme, let patterns = item.colorPatterns, !patterns.isEmpty {
          ThemePreview(patterns: patterns, showsBothSchemes: item.colorScheme == .both)
            // Centered vertically between subtitle and metadata
            .padding(.top, 12)
            // Decorative illustration; the row already conveys the theme textually.
            .accessibilityHidden(true)
        }

        if item.isLocal || !item.author.isEmpty || item.version != nil || item.homepage != nil {
          HStack(spacing: 5) {
            if item.isLocal {
              Text(Localized.Extension.local)
                .font(.callout)
                .foregroundStyle(.secondary)
            } else if let version = item.version {
              Text(verbatim: "v\(version)")
                .font(.callout)
                .foregroundStyle(.secondary)
                .contentTransition(.numericText())
            }

            if !item.author.isEmpty {
              if item.version != nil || item.isLocal {
                metadataDot
              }

              Text(item.author)
                .font(.callout)
                .foregroundStyle(.secondary)
            }

            if let homepage = item.homepage {
              if item.version != nil || item.isLocal || !item.author.isEmpty {
                metadataDot
              }

              Link(Localized.Extension.homepage, destination: homepage)
                .font(.callout)
                .fontWeight(.medium)
                .help(homepage.absoluteString)
            }
          }
          .padding(.top, 12)
          // Only animate the row being upgraded, not tab switches.
          .animation(isItemBusy ? .easeInOut(duration: 0.25) : nil, value: item.version)
        }
      }

      Spacer()

      // Centered vertically on the cell
      trailingControl(item: item)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, rowMargin)
    .frame(maxWidth: .infinity)
    .background(
      // Rounded for the drag preview; invisible at rest since it matches the content background.
      RoundedRectangle(cornerRadius: 8)
        .fill(Self.contentBackgroundStyle)
    )
    // Fresh identity per mode so tab switches swap content without animating.
    .id(model.mode)
  }
}

// MARK: - Private

private extension ExtensionsRowView {
  static var contentBackgroundStyle: AnyShapeStyle {
    if #available(macOS 26.0, *) {
      return .init(.windowBackground)
    }

    return .init(Color(.finderContentBackground))
  }

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
      // Non-interactive while busy; only the triggering button shows the spinner.
      .disabled(isItemBusy)
      .animation(.easeInOut(duration: 0.25), value: isItemBusy)
      // Intrinsic width so a narrow window truncates metadata, not the titles.
      .fixedSize(horizontal: true, vertical: false)
      .layoutPriority(1)
  }

  /// Spinner overlay on a single busy button, hiding its title.
  @ViewBuilder
  func busyControl<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
    content()
      .opacity(isItemBusy ? 0 : 1)
      .overlay {
        SpinningRing()
          .opacity(isItemBusy ? 1 : 0)
          .allowsHitTesting(false)
      }
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
      busyControl {
        PillButton(Localized.Extension.installButton, style: .prominent) {
          Task {
            await model.installExtension(item)
          }
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
      busyControl {
        PillButton(String(format: Localized.Extension.updateToFormat, updateVersion), style: .bordered) {
          Task {
            await model.updateExtension(item)
          }
        }
      }
      .help(item.updateNotes ?? "")
    }
  }

  /// The pending-update badge ("↑ 1.2.3"); links to a browsable page for the latest release when available.
  func updateBadge(version: String, url: URL?) -> some View {
    let title = Text(verbatim: "↑ \(version)")
      .font(.callout)
      .fontWeight(.medium)

    return Group {
      if let url {
        // Keep the default link style so it dims on mouse down
        Link(destination: url) { title }
          .help(url.absoluteString)
      } else {
        title.foregroundStyle(.tint)
      }
    }
    .accessibilityLabel(String(format: Localized.Extension.updateToFormat, version))
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
