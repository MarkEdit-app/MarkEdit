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
  let listInteraction: ExtensionsListInteraction
  let rowMargin: Double
  let rowHeightChanged: () -> Void

  @State private var showingUpdatePopover = false

  var body: some View {
    // Read live state so the cell animates its own updates instead of being reloaded
    let item = liveItem

    HStack(spacing: 10) {
      VStack(alignment: .leading, spacing: 6) {
        HStack(spacing: 6) {
          Image(systemName: systemSymbol(for: item))
            .foregroundStyle(.secondary)
            .accessibilityHidden(true)

          HighlightedText(
            item.displayName,
            query: searchQuery,
            isRevealed: model.highlightedItemID == item.id
          )
          .font(.title3)
          .fontWeight(.semibold)
          .lineLimit(1)

          if item.isFeatured, model.mode == .discover {
            if #available(macOS 15.1, *) {
              HStack(spacing: 4) {
                Image(systemName: Icons.laurelLeading)
                  .bold()
                  .foregroundStyle(LinearGradient.spectrum(direction: .leftToRight))
                  .accessibilityHidden(true)

                Text(Localized.Extension.featured)
                  .font(.callout)
                  .fontDesign(.serif)
                  .foregroundStyle(.secondary)

                Image(systemName: Icons.laurelTrailing)
                  .bold()
                  .foregroundStyle(LinearGradient.spectrum(direction: .rightToLeft))
                  .accessibilityHidden(true)
              }
            } else {
              Image(systemName: "rosette")
                .bold()
                .foregroundStyle(.orange)
                .help(Localized.Extension.featured)
                .accessibilityLabel(Localized.Extension.featured)
            }
          }

          // Skip in Discover, where many rows repeat the same version and it's noisy
          if let updateVersion = item.updateVersion, model.mode != .discover {
            updateBadge(version: updateVersion, url: item.latestReleaseURL)
              .transition(.opacity.combined(with: .scale))
          }
        }
        // Only animate the row being upgraded, not tab switches
        .animation(isItemBusy ? .easeInOut(duration: 0.25) : nil, value: item.updateVersion)

        if let summary = updateSummary(for: item) {
          Button {
            if showingUpdateInline {
              listInteraction.inlineUpdateItemIDs.remove(item.id)
            } else {
              listInteraction.inlineUpdateItemIDs.insert(item.id)
            }

            rowHeightChanged()
          } label: {
            subtitle(showingUpdateInline ? item.details : summary.notes)
          }
          .buttonStyle(.plain)
        } else if !item.details.isEmpty {
          subtitle(item.details)
        }

        if item.category == .theme, let patterns = item.colorPatterns, !patterns.isEmpty {
          ThemePreview(patterns: patterns, showsBothSchemes: item.colorScheme == .both)
          // Centered vertically between subtitle and metadata
            .padding(.top, 12)
          // Decorative illustration; the row already conveys the theme textually
            .accessibilityHidden(true)
        }

        let segments = metadataSegments(for: item)
        if !segments.isEmpty {
          HStack(spacing: 5) {
            ForEach(segments.indices, id: \.self) { index in
              if index > 0 {
                metadataDot
              }

              segments[index]
            }
          }
          .lineLimit(1)
          .truncationMode(.tail)
          .padding(.top, 12)
          // Only animate the row being upgraded, not tab switches
          .animation(isItemBusy ? .easeInOut(duration: 0.25) : nil, value: item.version)
        }
      }
      .frame(maxWidth: .infinity, alignment: .leading)

      // Centered vertically on the cell
      trailingControl(item: item)
    }
    .padding(.vertical, 8)
    .padding(.horizontal, rowMargin)
    .frame(maxWidth: .infinity)
    .background(
      // Rounded for the drag preview; invisible at rest since it matches the content background
      RoundedRectangle(cornerRadius: 8)
        .fill(Self.contentBackgroundStyle)
    )
    // Fresh identity per mode and item so tab switches and cell reuse reset row state
    .id("\(model.mode):\(item.id)")
    .onChange(of: listInteraction.scrollGeneration) {
      showingUpdatePopover = false
    }
  }

  var sizingSubtitleText: String? {
    let item = liveItem
    if let summary = updateSummary(for: item) {
      return showingUpdateInline ? item.details : summary.notes
    }

    return item.details.isEmpty ? nil : item.details
  }

  func sizingSubtitle(_ text: String) -> some View {
    subtitle(text)
  }

  var sizingTrailingControl: some View {
    trailingControl(item: liveItem)
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

  /// Trimmed search query, tinted in rows to show why an item matched.
  var searchQuery: String {
    model.searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var showingUpdateInline: Bool {
    listInteraction.inlineUpdateItemIDs.contains(item.id)
  }

  func subtitle(_ text: String) -> some View {
    Text(text, highlighting: searchQuery)
      .font(.body)
      .foregroundStyle(.secondary)
      .lineLimit(3)
      .truncationMode(.tail)
  }

  func systemSymbol(for item: ExtensionsModel.Item) -> String {
    if item.isLocal {
      return Icons.wrenchAndScrewdriver
    }

    return item.category == .theme ? Icons.paintpalette : Icons.puzzlepieceExtension
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
    // Non-interactive while busy; only the triggering button shows the spinner
      .disabled(isItemBusy)
      .animation(.easeInOut(duration: 0.25), value: isItemBusy)
    // Intrinsic width so a narrow window truncates metadata, not the titles
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
    if model.mode.isLocalList {
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
        PillButton(Localized.Extension.installButton, style: .bordered) {
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
      // Stays enabled, clicking it explains the requirement
      let requirement = item.unmetAppVersion.map {
        String(format: Localized.Extension.incompatibleFormat, $0)
      }

      busyControl {
        PillButton(Localized.Extension.updateButton, style: requirement == nil ? .prominent : .bordered) {
          Task {
            await model.updateExtension(item)
          }
        }
        .help(requirement ?? String(format: Localized.Extension.updateToFormat, updateVersion))
      }
    }
  }

  /// The pending-update badge ("↑ 1.2.3"); opens a browsable page for the latest release when available.
  func updateBadge(version: String, url: URL?) -> some View {
    let title = Text(verbatim: "↑ \(version)")
      .font(.callout)
      .fontWeight(.medium)
      .foregroundStyle(.tint)

    return Group {
      if let url {
        Button {
          NSWorkspace.shared.open(url)
        } label: {
          title
        }
        .buttonStyle(.plain)
        .help(url.absoluteString)
        .accessibilityAddTraits(.isLink)
      } else {
        title
      }
    }
    .accessibilityLabel(String(format: Localized.Extension.updateToFormat, version))
  }

  func revealButton(for item: ExtensionsModel.Item) -> some View {
    PillButton(Localized.Extension.reveal, style: .bordered) {
      model.revealScriptFile(item)
    }
  }

  func updateNotesPopover(_ notes: String, releaseDate: Date?, releaseURL: URL?) -> some View {
    VStack(alignment: .leading, spacing: 0) {
      Text(Localized.Extension.whatsNew)
        .font(.title3)
        .fontWeight(.semibold)
        .padding(.bottom, 8)

      Text(notes)
        .font(.body)
        .textSelection(.enabled)
        .fixedSize(horizontal: false, vertical: true)
        .padding(.bottom, 16)

      if releaseDate != nil || releaseURL != nil {
        Divider()

        HStack(spacing: 12) {
          if let releaseDate {
            HStack(spacing: 4) {
              Image(systemName: "calendar")
                .accessibilityHidden(true)
              Text(formattedReleaseDate(releaseDate))
            }
            .font(.body)
            .foregroundStyle(.secondary)
          }

          Spacer()

          if let releaseURL {
            Button(Localized.Extension.viewRelease) {
              showingUpdatePopover = false
              NSWorkspace.shared.open(releaseURL)
            }
            .help(releaseURL.absoluteString)
          }
        }
        .padding(.top, 16)
      }
    }
    .frame(width: 320, alignment: .leading)
    .padding(16)
    .background(Color(.windowBackgroundColor).opacity(0.3))
  }

  var metadataDot: some View {
    Text(verbatim: "·")
      .bold()
      .foregroundStyle(.secondary)
      .accessibilityHidden(true)
  }

  /// Metadata line segments (version/local, what's new, author, homepage), type-erased so they
  /// can be interleaved with dots via a single `ForEach` instead of a chain of conditionals.
  func metadataSegments(for item: ExtensionsModel.Item) -> [AnyView] {
    guard (item.isLocal && !item.isUntracked) || !item.author.isEmpty || item.version != nil || item.homepage != nil || item.updateNotes != nil else {
      return []
    }

    var segments: [AnyView] = []
    if item.isLocal {
      segments.append(AnyView(
        Text(Localized.Extension.local)
          .font(.callout)
          .foregroundStyle(.secondary)
      ))
    } else if let version = item.version {
      segments.append(AnyView(
        Text(verbatim: "v\(version)")
          .font(.callout)
          .foregroundStyle(.secondary)
          .contentTransition(.numericText())
      ))
    }

    if let summary = updateSummary(for: item) {
      segments.append(AnyView(
        Text(summary.date.formatted(date: .abbreviated, time: .omitted))
          .font(.callout)
          .foregroundStyle(.secondary)
      ))
    } else if let notes = item.updateNotes {
      segments.append(AnyView(
        Button(Localized.Extension.whatsNew) {
          showingUpdatePopover = true
        }
          .buttonStyle(.plain)
          .font(.callout)
          .fontWeight(.medium)
          .foregroundStyle(.tint)
          .popover(isPresented: $showingUpdatePopover, arrowEdge: .bottom) {
            updateNotesPopover(notes, releaseDate: item.releaseDate, releaseURL: item.releasePageURL)
          }
          .onDisappear {
            showingUpdatePopover = false
          }
      ))
    }

    if !item.author.isEmpty {
      segments.append(AnyView(
        HStack(spacing: 5) {
          if item.isOfficial {
            Image(systemName: Icons.checkmarkSeal)
              .font(.callout)
              .imageScale(.small)
              .foregroundStyle(.secondary)
              .help(Localized.Extension.official)
              .accessibilityLabel(Localized.Extension.official)
          }

          Text(item.author, highlighting: searchQuery)
            .font(.callout)
            .foregroundStyle(.secondary)
        }
      ))
    }

    if let homepage = item.homepage {
      segments.append(AnyView(
        Button(Localized.Extension.homepage) {
          NSWorkspace.shared.open(homepage)
        }
          .buttonStyle(.plain)
          .font(.callout)
          .fontWeight(.medium)
          .foregroundStyle(.tint)
          .help(homepage.absoluteString)
          .accessibilityAddTraits(.isLink)
      ))
    }

    return segments
  }

  func updateSummary(for item: ExtensionsModel.Item) -> (notes: String, date: Date)? {
    model.mode == .updates ? item.updateSummary : nil
  }

  func formattedReleaseDate(_ date: Date, relativeTo referenceDate: Date = .now) -> String {
    let oneWeekAgo = Calendar.current.date(byAdding: .day, value: -7, to: referenceDate) ?? referenceDate
    if date < oneWeekAgo {
      return date.formatted(date: .abbreviated, time: .omitted)
    }

    let formatter = RelativeDateTimeFormatter()
    formatter.unitsStyle = .full
    return formatter.localizedString(for: date, relativeTo: referenceDate)
  }
}
