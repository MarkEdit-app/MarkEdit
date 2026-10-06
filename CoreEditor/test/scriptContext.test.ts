import { afterEach, beforeEach, describe, expect, jest, test } from '@jest/globals';
import type { TranslationService } from 'markedit-api';
import { createScriptContext, withScriptContext } from '../src/scriptContext';
import { initMarkEditModules } from '../src/api/modules';

beforeEach(initMarkEditModules);
afterEach(() => {
  jest.restoreAllMocks();
});

describe('script context', () => {
  test('retains each script binding when a function is called later', async () => {
    MarkEdit.getFileContent = withScriptContext(filePath => async (path?: string) => `${filePath}:${path}`);
    const first = createScriptContext('/scripts/first.js').MarkEdit;
    const second = createScriptContext('/scripts/second.js').MarkEdit;
    const { getFileContent } = first;

    expect(first.getFileContent).toBe(getFileContent);
    expect(second.getFileContent).not.toBe(getFileContent);

    await expect(Promise.all([
      Promise.resolve().then(() => getFileContent('a')),
      second.getFileContent('b'),
    ])).resolves.toEqual(['/scripts/first.js:a', '/scripts/second.js:b']);

    expect(() => MarkEdit.getFileContent('a')).toThrow('script-local MarkEdit');
  });

  test('creates and caches an API object once per script', async () => {
    const factory = jest.fn((filePath: string): TranslationService => ({
      translate: async text => ({ succeeded: true, text: `${filePath}:${text}` }),
    }));

    MarkEdit.translationService = withScriptContext(factory);
    const first = createScriptContext('/scripts/first.js').MarkEdit;
    const second = createScriptContext('/scripts/second.js').MarkEdit;
    expect(factory).not.toHaveBeenCalled();

    const service = first.translationService;
    const { translate } = service;
    expect(first.translationService).toBe(service);
    expect(second.translationService).not.toBe(service);

    await expect(Promise.all([
      Promise.resolve().then(() => translate('a')),
      second.translationService.translate('b'),
    ])).resolves.toEqual([
      { succeeded: true, text: '/scripts/first.js:a' },
      { succeeded: true, text: '/scripts/second.js:b' },
    ]);

    expect(factory).toHaveBeenCalledTimes(2);
    expect(() => MarkEdit.translationService.translate('a')).toThrow('script-local MarkEdit');
  });

  test('preserves shared APIs and binds the CommonJS export', () => {
    const context = createScriptContext('/scripts/test.js');
    expect(context.MarkEdit.openFile).toBe(MarkEdit.openFile);
    expect(context.MarkEdit.editorAPI).toBe(MarkEdit.editorAPI);

    MarkEdit.playSystemBeep = jest.fn();
    expect(context.MarkEdit.playSystemBeep).toBe(MarkEdit.playSystemBeep);

    context.MarkEdit.playSystemBeep = context.MarkEdit.terminateApp;
    expect(MarkEdit.playSystemBeep).toBe(MarkEdit.terminateApp);
    expect(context.require?.('markedit-api').MarkEdit).toBe(context.MarkEdit);
    expect(context.require?.('markedit-api')).toBe(context.require?.('markedit-api'));
    expect(context.require?.('@codemirror/view')).toBe(MarkEdit.codemirror.view);
    expect(window.require('markedit-api').MarkEdit).toBe(MarkEdit);
  });

  test('leaves require absent in Quick Look', () => {
    const require = window.require;
    Reflect.deleteProperty(window, 'require');
    try {
      expect(createScriptContext('/scripts/quicklook.js').require).toBeUndefined();
    } finally {
      window.require = require;
    }
  });
});
