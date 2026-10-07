import { beforeEach, describe, expect, jest, test } from '@jest/globals';
import { initMarkEditModules } from '../src/api/modules';
import { createScriptContext } from '../src/scriptContext';
import { createNativeModule } from '../src/bridge/nativeModule';
import { NativeModuleSecretStorage } from '../src/bridge/native/secretStorage';

const postMessage = jest.fn<(message: {
  moduleName: string;
  methodName: string;
  parameters: string;
}) => Promise<unknown>>();

beforeEach(() => {
  initMarkEditModules();
  postMessage.mockReset();
  window.webkit = { messageHandlers: { bridge: { postMessage } } };
  window.nativeModules.secretStorage = createNativeModule<NativeModuleSecretStorage>('secretStorage');
});

function storageFor(capability: string) {
  return createScriptContext('/scripts/test.js', capability).MarkEdit.secretStorage;
}

describe('secretStorage', () => {
  test('has sends the bound capability and key', async () => {
    postMessage.mockResolvedValue('{"value":true}');
    await expect(storageFor('/scripts/a.js').has('token')).resolves.toBe(true);
    expect(postMessage).toHaveBeenCalledWith({
      moduleName: 'secretStorage',
      methodName: 'has',
      parameters: JSON.stringify({ capability: '/scripts/a.js', key: 'token' }),
    });
  });

  test('get preserves empty secrets and normalizes a missing native value', async () => {
    postMessage.mockResolvedValueOnce('{"value":""}').mockResolvedValueOnce('{}').mockResolvedValueOnce('{"value":"token"}');
    const secrets = storageFor('script-a');
    await expect(secrets.get('token')).resolves.toBe('');
    await expect(secrets.get('missing')).resolves.toBeUndefined();
    await expect(secrets.get('token')).resolves.toBe('token');
    expect(postMessage).toHaveBeenCalledWith({
      moduleName: 'secretStorage',
      methodName: 'get',
      parameters: JSON.stringify({ capability: 'script-a', key: 'token' }),
    });
  });

  test('set does not return a native result and delete preserves absence', async () => {
    postMessage.mockResolvedValueOnce('{}').mockResolvedValueOnce('{"value":false}');
    const secrets = storageFor('script-a');
    await expect(secrets.set('token', 'secret')).resolves.toBeUndefined();
    expect(postMessage).toHaveBeenCalledWith({
      moduleName: 'secretStorage',
      methodName: 'set',
      parameters: JSON.stringify({ capability: 'script-a', key: 'token', value: 'secret' }),
    });

    await expect(secrets.delete('missing')).resolves.toBe(false);
    expect(postMessage).toHaveBeenCalledWith({
      moduleName: 'secretStorage',
      methodName: 'delete',
      parameters: JSON.stringify({ capability: 'script-a', key: 'missing' }),
    });
  });

  test('all operations propagate failures', async () => {
    const error = new Error('Keychain unavailable');
    postMessage.mockRejectedValue(error);
    const secrets = storageFor('script-a');
    await expect(secrets.has('token')).rejects.toBe(error);
    await expect(secrets.get('token')).rejects.toBe(error);
    await expect(secrets.set('token', 'value')).rejects.toBe(error);
    await expect(secrets.delete('token')).rejects.toBe(error);
  });

  test.each(['await', 'then', 'catch', 'finally'])('shared Promise hooks cannot observe an approved secret via %s', async method => {
    postMessage.mockResolvedValue('{"value":"private-secret"}');
    const secrets = storageFor('victim-capability');
    const constructor = Object.getOwnPropertyDescriptor(Promise.prototype, 'constructor');
    const then = Object.getOwnPropertyDescriptor(Promise.prototype, 'then');
    const species = Object.getOwnPropertyDescriptor(Promise, Symbol.species);
    if (!constructor || !then || !species) {
      throw new Error('Missing built-in Promise descriptors.');
    }

    const intercepted: unknown[] = [];
    let value: string | undefined;

    try {
      Object.defineProperty(Promise.prototype, 'constructor', { value: {}, configurable: true });
      Promise.prototype.then = new Proxy(Promise.prototype.then, {
        apply(target, receiver, [onFulfilled, onRejected]) {
          return Reflect.apply(target, receiver, [(result: unknown) => {
            intercepted.push(result);
            return typeof onFulfilled === 'function' ? onFulfilled(result) : result;
          }, onRejected]);
        },
      });

      Object.defineProperty(Promise, Symbol.species, {
        value: new Proxy(Promise, {
          construct(target, [executor]) {
            return new target((resolve, reject) => {
              executor((result: unknown) => {
                intercepted.push(result);
                resolve(result);
              }, reject);
            });
          },
        }),
        configurable: true,
      });

      const result = secrets.get('token');
      switch (method) {
        case 'then':
          value = await result.then(value => value);
          break;
        case 'catch':
          value = await result.catch(() => undefined);
          break;
        case 'finally':
          value = await result.finally(() => {});
          break;
        default:
          value = await result;
      }
    } finally {
      Object.defineProperty(Promise.prototype, 'constructor', constructor);
      Object.defineProperty(Promise.prototype, 'then', then);
      Object.defineProperty(Promise, Symbol.species, species);
    }

    expect(value).toBe('private-secret');
    expect(intercepted).not.toContain('{"value":"private-secret"}');
    expect(intercepted).not.toContain('private-secret');
  });

  test('all operations reject native error responses', async () => {
    postMessage.mockResolvedValue('{"error":"Access cancelled"}');
    const secrets = storageFor('/scripts/a.js');
    await expect(secrets.has('token')).rejects.toThrow('Access cancelled');
    await expect(secrets.get('token')).rejects.toThrow('Access cancelled');
    await expect(secrets.set('token', 'value')).rejects.toThrow('Access cancelled');
    await expect(secrets.delete('token')).rejects.toThrow('Access cancelled');
  });

  test('malformed responses reject instead of appearing to be missing secrets', async () => {
    const secrets = storageFor('/scripts/a.js');
    for (const response of ['null', '[]', '{"unexpected":true}', '{"value":false}']) {
      postMessage.mockResolvedValue(response);
      await expect(secrets.get('token')).rejects.toThrow('Invalid secret storage');
    }
  });

  test('unbound access fails without contacting native', () => {
    expect(() => MarkEdit.secretStorage.has('token')).toThrow('script-local MarkEdit');
    expect(() => MarkEdit.secretStorage.get('token')).toThrow('script-local MarkEdit');
    expect(() => MarkEdit.secretStorage.set('token', 'value')).toThrow('script-local MarkEdit');
    expect(() => MarkEdit.secretStorage.delete('token')).toThrow('script-local MarkEdit');
    expect(postMessage).not.toHaveBeenCalled();
  });

  test('a missing native host rejects instead of logging secrets or hanging', async () => {
    window.webkit = undefined;
    await expect(storageFor('script-a').set('token', 'secret')).rejects.toThrow('native MarkEdit app');
  });

  test('set rejects an unexpected result', async () => {
    postMessage.mockResolvedValue('{"value":false}');
    await expect(storageFor('script-a').set('token', 'secret')).rejects.toThrow('Invalid secret storage result');
  });

  test('storage methods retain their own capabilities', async () => {
    postMessage.mockResolvedValue('{}');
    const { get } = storageFor('/scripts/a.js');
    await Promise.all([
      Promise.resolve().then(() => get('token')),
      storageFor('/scripts/b.js').get('token'),
    ]);

    expect(postMessage.mock.calls.map(([message]) => JSON.parse(message.parameters).capability).sort()).toEqual([
      '/scripts/a.js', '/scripts/b.js',
    ]);
  });

  test('a public path-only context cannot use secret storage', async () => {
    const secrets = createScriptContext('/scripts/victim.js').MarkEdit.secretStorage;
    await expect(secrets.has('token')).rejects.toThrow('script-local MarkEdit');
    expect(postMessage).not.toHaveBeenCalled();
  });

  test('non-string arguments reject before serialization', async () => {
    const secrets = storageFor('capability');
    const key = { toJSON: jest.fn() };
    // @ts-expect-error Exercise malicious JavaScript callers.
    await expect(secrets.get(key)).rejects.toThrow('Invalid secret storage arguments');
    // @ts-expect-error Exercise malicious JavaScript callers.
    await expect(secrets.set('key', key)).rejects.toThrow('Invalid secret storage arguments');
    expect(key.toJSON).not.toHaveBeenCalled();
    expect(postMessage).not.toHaveBeenCalled();
  });
});
