import { afterEach, describe, expect, jest, test } from '@jest/globals';
import { EditorView } from '@codemirror/view';
import { notifyEditorConfigChange, notifyEditorReady, onEditorConfigChange, onEditorReady } from '../src/api/methods';
import { initMarkEditModules } from '../src/api/modules';
import { createNativeModule } from '../src/bridge/nativeModule';
import { NativeModuleAPI } from '../src/bridge/native/api';
import { OpenPanelOptions, ToolbarItem } from 'markedit-api';
import { getMenuItemStates, handleMainMenuAction } from '../src/api/ui';
import { WebToolbarItem } from '../src/@types/WebToolbarItem';

afterEach(() => {
  jest.restoreAllMocks();
});

describe('toolbar declarations', () => {
  function register(item: ToolbarItem | ToolbarItem[]) {
    const posted = jest.fn<(message: { moduleName: string; methodName: string; parameters: string }) => Promise<void>>().mockResolvedValue(undefined);
    window.webkit = { messageHandlers: { bridge: { postMessage: posted } } };
    window.nativeModules.api = createNativeModule<NativeModuleAPI>('api');
    initMarkEditModules();

    MarkEdit.addToolbarItem(item);
    expect(posted).toHaveBeenCalledTimes(1);
    expect(posted.mock.calls[0][0].methodName).toBe('addToolbarItems');

    const { items } = JSON.parse(posted.mock.calls[0][0].parameters) as { items: WebToolbarItem[] };
    posted.mockClear();
    return { items, posted };
  }

  test.each([false, true])('registers actions and refreshes state after execution (throws: %s)', async fails => {
    let selected = false;
    const id = `preview.mode.${fails}`;
    const { items: [item], posted } = register({
      id, title: 'Modes', icon: 'eye', type: 'segmented',
      segments: [{
        title: 'Source', icon: 'pencil', state: () => ({ isSelected: selected }),
        action() {
          selected = true;
          if (fails) {
            throw new Error('Expected action failure');
          }
        },
      }],
    });

    const segment = item.segments[0];
    expect(getMenuItemStates([segment.stateGetterID])).toEqual([{ isSelected: false }]);
    if (fails) {
      expect(() => handleMainMenuAction(segment.actionID)).toThrow('Expected action failure');
    } else {
      handleMainMenuAction(segment.actionID);
    }

    await Promise.resolve();
    expect(getMenuItemStates([segment.stateGetterID])).toEqual([{ isSelected: true }]);
    expect(posted).toHaveBeenCalledTimes(1);
    expect(posted).toHaveBeenCalledWith({
      moduleName: 'api', methodName: 'invalidateToolbarItem', parameters: JSON.stringify({ id }),
    });

    MarkEdit.invalidateToolbarItem(id);
    MarkEdit.invalidateToolbarItem(id);
    await Promise.resolve();
    expect(posted).toHaveBeenCalledTimes(2);
  });

  test('reads and copies all states before queued changes can run', async () => {
    let selected = 0;
    const shared = { isSelected: false };
    const { items: [item] } = register({
      id: 'preview.snapshot', type: 'segmented', title: 'Modes', icon: 'eye',
      segments: [0, 1].map(index => ({
        title: String(index), icon: 'eye', action() {},
        state() {
          queueMicrotask(() => { selected = 1; });
          shared.isSelected = selected === index;
          return shared;
        },
      })),
    });

    const ids = item.segments.map(segment => segment.stateGetterID);
    expect(getMenuItemStates(ids)).toEqual([{ isSelected: true }, { isSelected: false }]);

    await Promise.resolve();
    expect(getMenuItemStates(ids)).toEqual([{ isSelected: false }, { isSelected: true }]);
  });

});

describe('openDocument', () => {
  test.each([
    [undefined, true],
    ['tab', true],
    ['window', false],
  ] as const)('forwards target %s and returns %s', async (target, result) => {
    initMarkEditModules();
    const postMessage = jest.fn<(message: {
      moduleName: string;
      methodName: string;
      parameters: string;
    }) => Promise<boolean>>().mockResolvedValue(result);

    window.webkit = { messageHandlers: { bridge: { postMessage } } };
    window.nativeModules.api = createNativeModule<NativeModuleAPI>('api');

    await expect(MarkEdit.openDocument('/tmp/document.md', target ? { target } : undefined)).resolves.toBe(result);
    expect(postMessage).toHaveBeenCalledTimes(1);
    expect(postMessage).toHaveBeenCalledWith({
      moduleName: 'api',
      methodName: 'openDocument',
      parameters: JSON.stringify({ path: '/tmp/document.md', target }),
    });
  });

});

describe('showOpenPanel', () => {
  const cases: { options?: OpenPanelOptions; result?: string[] }[] = [
    { result: ['/tmp/document.md'] },
    { options: { selectionType: 'files' }, result: ['/tmp/document.md'] },
    { options: { selectionType: 'directories' }, result: ['/tmp/folder'] },
    {
      options: {
        title: 'Select items',
        message: 'Choose files or folders.',
        prompt: 'Choose',
        selectionType: 'both',
        allowsMultipleSelection: true,
      },
      result: ['/tmp/document.md', '/tmp/folder'],
    },
    { options: {} },
  ];

  test.each(cases)('forwards $options and returns $result', async ({ options, result }) => {
    initMarkEditModules();
    const postMessage = jest.fn<(message: {
      moduleName: string;
      methodName: string;
      parameters: string;
    }) => Promise<string[] | undefined>>().mockResolvedValue(result);

    window.webkit = { messageHandlers: { bridge: { postMessage } } };
    window.nativeModules.api = createNativeModule<NativeModuleAPI>('api');

    await expect(MarkEdit.showOpenPanel(options)).resolves.toEqual(result);
    expect(postMessage).toHaveBeenCalledTimes(1);
    expect(postMessage).toHaveBeenCalledWith({
      moduleName: 'api',
      methodName: 'showOpenPanel',
      parameters: JSON.stringify({ options: options ?? {} }),
    });
  });
});

describe('onEditorReady', () => {
  test('notifies later listeners when one throws', () => {
    window.editor = document.createElement('div') as unknown as EditorView;
    const error = new Error('Failed listener');
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
    const listener = jest.fn();

    onEditorReady(() => { throw error; });
    onEditorReady(listener);

    const editor = { dispatch() {} } as unknown as EditorView;
    notifyEditorReady(editor);

    expect(consoleError).toHaveBeenCalledWith('Failed to notify an editor-ready listener:', error);
    expect(listener).toHaveBeenCalledWith(editor);
  });

  test('isolates a listener registered after the editor is ready', () => {
    window.editor = { dispatch() {} } as unknown as EditorView;
    const error = new Error('Failed listener');
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});

    expect(() => onEditorReady(() => { throw error; })).not.toThrow();
    expect(consoleError).toHaveBeenCalledWith('Failed to notify an editor-ready listener:', error);
  });
});

describe('onEditorConfigChange', () => {
  test('notifies listeners with the changed key and value', () => {
    const error = new Error('Failed listener');
    const consoleError = jest.spyOn(console, 'error').mockImplementation(() => {});
    const listener = jest.fn();

    onEditorConfigChange(() => { throw error; });
    onEditorConfigChange(listener);
    notifyEditorConfigChange('fontSize', 18);

    expect(consoleError).toHaveBeenCalledWith('Failed to notify an editor-config-change listener:', error);
    expect(listener).toHaveBeenCalledWith('fontSize', 18);
  });
});
