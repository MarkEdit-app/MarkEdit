import { v4 as UUID } from 'uuid';
import { MenuItem, Alert, TextBox } from 'markedit-api';

import { WebMenuItem } from '../@types/WebMenuItem';
import { WebPoint } from '../@types/WebPoint';
import { afterDomUpdate } from '../common/utils';
import { getRect, scrollToSelection, isPositionVisible } from '../modules/selection';

export function addMainMenuItem(spec: MenuItem | MenuItem[]): void {
  const items = Array.isArray(spec) ? spec : [spec];
  window.nativeModules.ui.addMainMenuItems({
    items: items.map(item => createMenuItem(item, mainActions)),
  });
}

export function showContextMenu(items: MenuItem[], location?: WebPoint) {
  const caretPos = window.editor.state.selection.main.head;
  const invokeNative = () => {
    window.nativeModules.ui.showContextMenu({
      items: items.map(item => createMenuItem(item, contextActions)),
      location: location ?? (() => {
        const rect = getRect(caretPos);
        if (rect === undefined) {
          // Basically invalid, it should not happen
          return { x: 0, y: 0 };
        }

        // Default value set to the caret position
        return { x: rect.x, y: rect.y + rect.height + 10 };
      })(),
    });
  };

  if (location === undefined && !isPositionVisible(caretPos)) {
    scrollToSelection('nearest');
    afterDomUpdate(invokeNative);
  } else {
    invokeNative();
  }
}

export function showAlert(spec: Alert): Promise<number> {
  const alert = typeof spec === 'string' ? { title: spec } : spec;
  return window.nativeModules.ui.showAlert(alert);
}

export function showTextBox(spec?: TextBox): Promise<string | undefined> {
  const textBox = typeof spec === 'string' ? { title: spec } : spec;
  return window.nativeModules.ui.showTextBox(textBox ?? {});
}

export function handleMainMenuAction(id: string) {
  const action = mainActions.get(id);
  if (action !== undefined) {
    action();
  }

  // Don't delete the action because main menu is available the entire app life cycle
}

export function handleContextMenuAction(id: string) {
  const action = contextActions.get(id);
  if (action !== undefined) {
    action();
  }

  // Release contextual menus as soon as one action is performed
  contextActions.clear();
}

function createMenuItem(item: MenuItem, actions: Map<string, () => void>): WebMenuItem {
  // Generate identifiers for actions so that native functions can retrieve and invoke them later
  const actionID = (() => {
    if (item.action === undefined) {
      return undefined;
    }

    const identifier = UUID();
    actions.set(identifier, item.action);
    return identifier;
  })();

  return {
    actionID,
    separator: item.separator ?? false,
    title: item.title,
    key: item.key,
    modifiers: item.modifiers,
    children: item.children?.map(item => createMenuItem(item, actions)),
  };
};

const mainActions = new Map<string, () => void>();
const contextActions = new Map<string, () => void>();
