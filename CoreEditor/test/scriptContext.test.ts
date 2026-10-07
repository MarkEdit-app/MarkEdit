import { afterEach, beforeEach, describe, expect, jest, test } from '@jest/globals';
import type { TranslationService } from 'markedit-api';
import { createScriptContext, createScriptRunner, withScriptContext } from '../src/scriptContext';
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
    expect(factory).toHaveBeenCalledTimes(2);

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

  test('runs Quick Look scripts without require or credential access', async () => {
    const require = window.require;
    const webkit = window.webkit;
    Reflect.deleteProperty(window, 'require');
    window.webkit = undefined;
    try {
      MarkEdit.getFileContent = withScriptContext(path => async () => path);
      const run = createScriptRunner([{ path: '/scripts/quicklook.js' }]);
      let api: typeof MarkEdit | undefined;
      run('/scripts/quicklook.js', (boundAPI, require) => {
        expect(require).toBeUndefined();
        api = boundAPI;
      });
      expect(api).toBeDefined();
      await expect(api?.getFileContent()).resolves.toBe('/scripts/quicklook.js');
      await expect(api?.secretStorage.get('token')).rejects.toThrow('native MarkEdit app');
    } finally {
      window.require = require;
      window.webkit = webkit;
    }
  });

  test('prepares private credentials before earlier scripts can intercept bindings or transport', async () => {
    const postMessage = jest.fn<(message: { parameters: string }) => Promise<string>>(async () => '{"value":true}');
    window.webkit = { messageHandlers: { bridge: { postMessage } } };
    const originals = {
      stringify: JSON.stringify,
      parse: JSON.parse,
      get: Reflect.get,
      apply: Reflect.apply,
      mapGet: Map.prototype.get,
      mapDelete: Map.prototype.delete,
      weakGet: WeakMap.prototype.get,
      bind: Function.prototype.bind,
      freeze: Object.freeze,
      require: window.require,
      Function: Function,
      native: window.nativeModules.secretStorage,
      webkit: window.webkit,
    };

    const intercepted: unknown[] = [];
    const results: Promise<boolean>[] = [];
    let deferred: (() => Promise<boolean>) | undefined;
    const run = createScriptRunner([
      { path: '/attacker.js', capability: 'attacker-capability' },
      { path: '/victim.js', capability: 'victim-private-capability' },
    ]);

    try {
      run('attacker-capability', () => {
        const hook = (...args: unknown[]): never => {
          intercepted.push(args);
          throw new Error('intercepted');
        };
        window.require = new Proxy<typeof window.require>(window.require, { apply: hook });
        window.nativeModules.secretStorage = { name: 'secretStorage', has: hook, get: hook, set: hook, delete: hook };
        window.webkit = { messageHandlers: { bridge: { postMessage: hook } } };
        JSON.stringify = hook;
        JSON.parse = hook;
        Reflect.get = hook;
        Reflect.apply = hook;
        Map.prototype.get = hook;
        Map.prototype.delete = hook;
        WeakMap.prototype.get = hook;
        Function.prototype.bind = hook;
        Object.assign(window, { Function: hook });
        Object.freeze = hook;
        Object.assign(Object.prototype, { toJSON: hook, capability: 'forged' });
      });
      run('victim-private-capability', (api, require) => {
        const required = require?.('markedit-api').MarkEdit as typeof MarkEdit;
        results.push(required.secretStorage.has('token'));
        deferred = () => api.secretStorage.has('later');
      });
    } finally {
      JSON.stringify = originals.stringify;
      JSON.parse = originals.parse;
      Reflect.get = originals.get;
      Reflect.apply = originals.apply;
      Map.prototype.get = originals.mapGet;
      Map.prototype.delete = originals.mapDelete;
      WeakMap.prototype.get = originals.weakGet;
      originals.Function.prototype.bind = originals.bind;
      Object.freeze = originals.freeze;
      window.require = originals.require;
      Object.assign(window, { Function: originals.Function });
      window.nativeModules.secretStorage = originals.native;
      window.webkit = originals.webkit;
      Reflect.deleteProperty(Object.prototype, 'toJSON');
      Reflect.deleteProperty(Object.prototype, 'capability');
    }

    expect(intercepted).toEqual([]);
    await expect(Promise.all(results)).resolves.toEqual([true]);
    await expect(deferred?.()).resolves.toBe(true);
    expect(postMessage.mock.calls).toHaveLength(2);

    for (const [message] of postMessage.mock.calls) {
      expect(JSON.parse(message.parameters).capability).toBe('victim-private-capability');
    }
  });

  test('rejects guessed and reused contexts without blocking later scripts', () => {
    const run = createScriptRunner([
      { path: '/first.js', capability: 'private-a' },
      { path: '/last.js', capability: 'private-b' },
    ]);
    const execute = jest.fn();
    expect(() => run('/first.js', execute)).toThrow('Script context is unavailable');
    expect(execute).not.toHaveBeenCalled();
    expect(() => run('private-a', () => { throw new Error('script failed'); })).toThrow('script failed');
    expect(() => run('private-a', execute)).toThrow('Script context is unavailable');
    run('private-b', execute);
    expect(execute).toHaveBeenCalledTimes(1);
  });
});
