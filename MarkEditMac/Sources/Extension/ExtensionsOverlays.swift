//
//  ExtensionsOverlays.swift
//  MarkEditMac
//
//  Created by cyan on 7/16/26.
//

import SwiftUI
import SharedUI

/// Loading / empty / registry-error state shown over the (otherwise empty) list.
struct ExtensionsStateView: View {
  let model: ExtensionsModel

  var body: some View {
    if let loadingMessage = model.loadingMessage {
      LabeledProgressView(
        title: loadingMessage,
        progress: model.updateProgress.map {
          Double($0.completed) / Double($0.total)
        }
      )
    } else if model.phase == .loading {
      ProgressView()
    } else if model.items.isEmpty {
      // Gate on the live item count so a mode switch doesn't flash a stale empty message
      emptyState
    }
  }
}

/// Bottom bar showing information like "relaunch needed".
struct ExtensionsInfoBar: View {
  let model: ExtensionsModel

  var body: some View {
    if model.pendingRelaunch {
      ActionableInfoBar(
        message: Localized.Extension.relaunchNotice,
        systemImage: Icons.exclamationmarkBubbleFill,
        iconColor: .yellow
      ) {
        Button(Localized.Extension.relaunchButton) {
          model.relaunch()
        }
      }
    }
  }
}

// MARK: - Private

private extension ExtensionsStateView {
  var isRegistryError: Bool {
    model.mode == .discover && model.phase == .failed
  }

  var emptyState: some View {
    VStack(spacing: 10) {
      Image(systemName: isRegistryError ? Icons.wifiSlash : Icons.puzzlepieceExtension)
        .font(.largeTitle)
        .foregroundStyle(.secondary)

      Text(emptyMessage)
        .foregroundStyle(.secondary)

      if isRegistryError {
        Button(Localized.Extension.retry) {
          Task {
            await model.load(forceRefresh: true)
          }
        }
      }
    }
    .padding()
  }

  var emptyMessage: String {
    if isRegistryError {
      return Localized.Extension.registryUnreachable
    }

    return model.mode.emptyMessage
  }
}
