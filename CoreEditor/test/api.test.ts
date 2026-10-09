import { afterEach, describe, expect, jest, test } from '@jest/globals';
import { EditorView } from '@codemirror/view';
import { notifyEditorConfigChange, notifyEditorReady, onEditorConfigChange, onEditorReady } from '../src/api/methods';
import { initMarkEditModules } from '../src/api/modules';
import { createNativeModule } from '../src/bridge/nativeModule';
import { NativeModuleAPI } from '../src/bridge/native/api';
import { OpenPanelOptions } from 'markedit-api';

afterEach(() => {
  jest.restoreAllMocks();
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
