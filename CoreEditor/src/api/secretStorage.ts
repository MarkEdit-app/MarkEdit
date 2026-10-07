/* eslint-disable promise/prefer-await-to-then -- Async functions would return promises with shared, mutable prototypes. */
import type { SecretStorage } from 'markedit-api';
import { withScriptContext } from '../scriptContext';
import { createContextRequest } from '../bridge/contextRequest';

const StorageError = Error;

export const secretStorage = withScriptContext((_path, capability): SecretStorage => {
  const send = createContextRequest('secretStorage', capability);

  function request(methodName: string, key: string, value?: string): Promise<unknown> {
    return send(methodName, () => {
      if (typeof key !== 'string' || (methodName === 'set' && typeof value !== 'string')) {
        throw new StorageError('Invalid secret storage arguments.');
      }

      return { key, value };
    });
  }

  return Object.freeze({
    has(key: string): Promise<boolean> {
      return request('has', key).then(booleanResult);
    },
    get(key: string): Promise<string | undefined> {
      return request('get', key).then(value => {
        if (value !== undefined && typeof value !== 'string') {
          throw new StorageError('Invalid secret storage value.');
        }

        return value;
      });
    },
    set(key: string, value: string): Promise<void> {
      return request('set', key, value).then(result => {
        if (result !== undefined) {
          throw new StorageError('Invalid secret storage result.');
        }

        return undefined;
      });
    },
    delete(key: string): Promise<boolean> {
      return request('delete', key).then(booleanResult);
    },
  });
});

function booleanResult(value: unknown): boolean {
  if (typeof value !== 'boolean') {
    throw new StorageError('Invalid secret storage result.');
  }

  return value;
}
