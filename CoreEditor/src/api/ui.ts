import { EditorView } from '@codemirror/view';
import { MenuItem, MenuItemState, ToolbarItem, ContextMenuOptions, Alert, TextBox, OpenPanelOptions, PrintPanelOptions, SavePanelOptions } from 'markedit-api';

import { WebMenuItem } from '../@types/WebMenuItem';
import { WebPoint } from '../@types/WebPoint';
import { WebToolbarItem, WebToolbarItemState } from '../@types/WebToolbarItem';
import { afterDomUpdate, focusedEditor, getClientRect } from '../common/utils';
import { scrollToSelection, isPositionVisible } from '../modules/selection';

export type { MenuItemState };

export function addMainMenuItem(spec: MenuItem | MenuItem[]): void {
  const items = Array.isArray(spec) ? spec : [spec];
  window.nativeModules.api.addMainMenuItems({
    items: items.map(item => createMenuItem(item, mainActions)),
  });
}

export function addToolbarItem(spec: ToolbarItem | ToolbarItem[]): void {
  const items = (Array.isArray(spec) ? spec : [spec]).flatMap((item): WebToolbarItem[] => {
    if (toolbarItemIDs.has(item.id)) {
      console.error('Duplicate toolbar item ID:', item.id);
      return [];
    }

    toolbarItemIDs.add(item.id);
    const metadata = {
      id: item.id,
      type: item.type,
      title: item.title,
      icon: item.icon,
      initialPlacement: item.initialPlacement ?? 'customization',
    };

    const afterAction = () => invalidateToolbarItem(metadata.id);
    if (item.type !== 'segmented') {
      const menuItem = createMenuItem(item, mainActions, afterAction);
      return [{
        ...metadata,
        actionID: menuItem.actionID,
        stateGetterID: menuItem.stateGetterID,
        children: menuItem.children,
      }];
    }

    return [
      {
        ...metadata,
        segments: item.segments.map(segment => ({
          title: segment.title,
          icon: segment.icon,
          actionID: registerAction(segment.action, mainActions, afterAction),
          stateGetterID: registerAction(segment.state, mainActions),
        })),
      },
    ];
  });

  if (items.length > 0) {
    window.nativeModules.api.addToolbarItems({ items });
  }
}

export function invalidateToolbarItem(id: string): void {
  if (!toolbarItemIDs.has(id)) {
    console.error('Unknown toolbar item ID:', id);
    return;
  }

  if (pendingToolbarInvalidations.has(id)) {
    return;
  }

  pendingToolbarInvalidations.add(id);
  queueMicrotask(() => {
    pendingToolbarInvalidations.delete(id);
    window.nativeModules.api.invalidateToolbarItem({ id });
  });
}

export function showContextMenu(items: MenuItem[], location?: WebPoint, options?: ContextMenuOptions) {
  let { highlightedIndex } = options ?? {};
  if (highlightedIndex !== undefined && !Number.isSafeInteger(highlightedIndex)) {
    console.error('showContextMenu: highlightedIndex must be a safe integer.', highlightedIndex);
    highlightedIndex = undefined;
  }

  const editor = focusedEditor() ?? window.editor;
  const caretPos = editor.state.selection.main.head;
  const invokeNative = () => {
    window.nativeModules.api.showContextMenu({
      items: items.map(item => createMenuItem(item, contextActions)),
      highlightedIndex: highlightedIndex === undefined ? undefined : (highlightedIndex as CodeGen_Int),
      location: location ?? (() => {
        const coords = editor.coordsAtPos(caretPos);
        if (coords === null) {
          // Basically invalid, it should not happen
          return { x: 0, y: 0 };
        }

        // Default value set to the caret position
        const rect = getClientRect(coords);
        return { x: rect.x, y: rect.y + rect.height + 10 };
      })(),
    });
  };

  // Nested carets may be clipped by any intervening scroll container
  if (location === undefined && (editor !== window.editor || !isPositionVisible(caretPos))) {
    if (editor === window.editor) {
      scrollToSelection('nearest');
    } else {
      editor.dispatch({ effects: EditorView.scrollIntoView(caretPos, { x: 'nearest', y: 'nearest' }) });
    }

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

export function showOpenPanel(options?: OpenPanelOptions): Promise<string[] | undefined> {
  return window.nativeModules.api.showOpenPanel({ options: options ?? {} });
}

export function showSavePanel(options: SavePanelOptions): Promise<boolean> {
  return window.nativeModules.api.showSavePanel({ options });
}

export function showPrintPanel(options: PrintPanelOptions): Promise<boolean> {
  if (!isSupportedPrintType(options.type)) {
    return Promise.reject(new Error(`Unsupported print content type: ${options.type}`));
  }

  return window.nativeModules.api.showPrintPanel({ options });
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

export function getMenuItemState(id: string): WebToolbarItemState {
  const action = mainActions.get(id) ?? contextActions.get(id);
  if (action === undefined) {
    return {};
  }

  return action() as WebToolbarItemState;
}

export function getMenuItemStates(ids: string[]): WebToolbarItemState[] {
  return ids.map(id => {
    if (!mainActions.has(id) && !contextActions.has(id)) {
      throw new Error(`Unknown menu state getter: ${id}`);
    }

    const { isEnabled, isSelected, title, icon } = getMenuItemState(id);
    return { isEnabled, isSelected, title, icon };
  });
}

function createMenuItem(item: MenuItem, actions: Map<string, ActionType>, afterAction?: () => void): WebMenuItem {
  return {
    actionID: item.action === undefined ? undefined : registerAction(item.action, actions, afterAction),
    stateGetterID: item.state === undefined ? undefined : registerAction(item.state, actions),
    separator: item.separator ?? false,
    title: item.title,
    icon: item.icon,
    key: item.key,
    modifiers: item.modifiers,
    children: item.children?.map(item => createMenuItem(item, actions, afterAction)),
  };
};

function registerAction(action: ActionType, actions: Map<string, ActionType>, afterAction?: () => void): string {
  const identifier = crypto.randomUUID();
  actions.set(identifier, afterAction === undefined ? action : () => {
    try {
      return action();
    } finally {
      afterAction();
    }
  });

  return identifier;
}

function isSupportedPrintType(type: string): boolean {
  return type === 'pdf';
}

type ActionType = () => void | WebToolbarItemState;
const mainActions = new Map<string, ActionType>();
const contextActions = new Map<string, ActionType>();
const toolbarItemIDs = new Set<string>();
const pendingToolbarInvalidations = new Set<string>();
