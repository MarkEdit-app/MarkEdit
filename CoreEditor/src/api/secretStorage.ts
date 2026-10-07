import type { SecretStorage } from 'markedit-api';
import { withScriptContext } from '../scriptContext';

export const secretStorage = withScriptContext((path): SecretStorage => Object.freeze({
  async has(key: string): Promise<boolean> {
    return booleanResult(await request(() => window.nativeModules.secretStorage.has({ path, key })));
  },
  async get(key: string): Promise<string | undefined> {
    const value = await request(() => window.nativeModules.secretStorage.get({ path, key }));
    if (value !== undefined && typeof value !== 'string') {
      throw new Error('Invalid secret storage value.');
    }

    return value;
  },
  async set(key: string, value: string): Promise<void> {
    if (await request(() => window.nativeModules.secretStorage.set({ path, key, value })) !== undefined) {
      throw new Error('Invalid secret storage result.');
    }
  },
  async delete(key: string): Promise<boolean> {
    return booleanResult(await request(() => window.nativeModules.secretStorage.delete({ path, key })));
  },
}));

async function request(send: () => Promise<string>): Promise<unknown> {
  if (!window.webkit?.messageHandlers?.bridge) {
    throw new Error('Secret storage requires the native MarkEdit app.');
  }

  const response: unknown = JSON.parse(await send());
  if (typeof response !== 'object' || response === null || Array.isArray(response)) {
    throw new Error('Invalid secret storage response.');
  }

  if ('error' in response) {
    throw new Error(typeof response.error === 'string' ? response.error : 'Invalid secret storage error.');
  }

  if (!('value' in response) && Object.keys(response).length !== 0) {
    throw new Error('Invalid secret storage response.');
  }

  return 'value' in response ? response.value : undefined;
}

function booleanResult(value: unknown): boolean {
  if (typeof value !== 'boolean') {
    throw new Error('Invalid secret storage result.');
  }

  return value;
}
