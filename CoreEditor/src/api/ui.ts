import { v4 as UUID } from 'uuid';
import { MenuItem, MenuItemState, Alert, TextBox, SavePanelOptions } from 'markedit-api';

import { WebMenuItem } from '../@types/WebMenuItem';
import { WebPoint } from '../@types/WebPoint';
import { afterDomUpdate } from '../common/utils';
import { getRect, scrollToSelection, isPositionVisible } from '../modules/selection';

export type { MenuItemState };

export function addMainMenuItem(spec: MenuItem | MenuItem[]): void {
  const items = Array.isArray(spec) ? spec : [spec];
  window.nativeModules.api.addMainMenuItems({
    items: items.map(item => createMenuItem(item, mainActions)),
  });
}

export function showContextMenu(items: MenuItem[], location?: WebPoint) {
  const caretPos = window.editor.state.selection.main.head;
  const invokeNative = () => {
    window.nativeModules.api.showContextMenu({
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
  return window.nativeModules.api.showAlert(alert);
}

export function showTextBox(spec?: TextBox): Promise<string | undefined> {
  const textBox = typeof spec === 'string' ? { title: spec } : spec;
  return window.nativeModules.api.showTextBox(textBox ?? {});
}

export function showSavePanel(options: SavePanelOptions): Promise<boolean> {
  return window.nativeModules.api.showSavePanel({ options });
}

export function runService(name: string, input?: string): Promise<boolean> {
  return window.nativeModules.api.runService({ name, input });
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

export function getMenuItemState(id: string) {
  const action = mainActions.get(id) ?? contextActions.get(id);
  if (action === undefined) {
    return {};
  }

  return action() as MenuItemState;
}

function createMenuItem(item: MenuItem, actions: Map<string, ActionType>): WebMenuItem {
  // Generate identifiers for actions so that native functions can retrieve and invoke them later
  const generateID = (action?: ActionType) => {
    if (action === undefined) {
      return undefined;
    }

    const identifier = UUID();
    actions.set(identifier, action);
    return identifier;
  };

  return {
    actionID: generateID(item.action),
    stateGetterID: generateID(item.state),
    separator: item.separator ?? false,
    title: item.title,
    icon: item.icon,
    key: item.key,
    modifiers: item.modifiers,
    children: item.children?.map(item => createMenuItem(item, actions)),
  };
};

type ActionType = () => void | MenuItemState;
const mainActions = new Map<string, ActionType>();
const contextActions = new Map<string, ActionType>();
