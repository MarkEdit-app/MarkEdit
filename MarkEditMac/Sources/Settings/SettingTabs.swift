//
//  SettingTabs.swift
//  MarkEditMac
//
//  Created by cyan on 1/26/23.
//

import SettingsUI

extension SettingsTabViewController {
  static var editor: Self {
    Self(EditorSettingsView(), title: Localized.Settings.editor, icon: Icons.characterCursorIbeam)
  }

  static var assistant: Self {
    Self(AssistantSettingsView(), title: Localized.Settings.assistant, icon: Icons.wandAndStars)
  }

  static var general: Self {
    Self(GeneralSettingsView(), title: Localized.Settings.general, icon: Icons.gearshape)
  }

  static var window: Self {
    Self(WindowSettingsView(), title: Localized.Settings.window, icon: Icons.macwindow)
  }
}
