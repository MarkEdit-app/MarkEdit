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

function storageFor(path: string) {
  return createScriptContext(path).MarkEdit.secretStorage;
}

describe('secretStorage', () => {
  test('has sends the bound path and key', async () => {
    postMessage.mockResolvedValue('{"value":true}');
    await expect(storageFor('/scripts/a.js').has('token')).resolves.toBe(true);
    expect(postMessage).toHaveBeenCalledWith({
      moduleName: 'secretStorage',
      methodName: 'has',
      parameters: JSON.stringify({ path: '/scripts/a.js', key: 'token' }),
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
      parameters: JSON.stringify({ path: 'script-a', key: 'token' }),
    });
  });

  test('set does not return a native result and delete preserves absence', async () => {
    postMessage.mockResolvedValueOnce('{}').mockResolvedValueOnce('{"value":false}');
    const secrets = storageFor('script-a');
    await expect(secrets.set('token', 'secret')).resolves.toBeUndefined();
    expect(postMessage).toHaveBeenCalledWith({
      moduleName: 'secretStorage',
      methodName: 'set',
      parameters: JSON.stringify({ path: 'script-a', key: 'token', value: 'secret' }),
    });

    await expect(secrets.delete('missing')).resolves.toBe(false);
    expect(postMessage).toHaveBeenCalledWith({
      moduleName: 'secretStorage',
      methodName: 'delete',
      parameters: JSON.stringify({ path: 'script-a', key: 'missing' }),
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

  test('storage methods retain their own script paths', async () => {
    postMessage.mockResolvedValue('{}');
    const { get } = storageFor('/scripts/a.js');
    await Promise.all([
      Promise.resolve().then(() => get('token')),
      storageFor('/scripts/b.js').get('token'),
    ]);

    expect(postMessage.mock.calls.map(([message]) => JSON.parse(message.parameters).path).sort()).toEqual([
      '/scripts/a.js', '/scripts/b.js',
    ]);
  });
});
