/* eslint-disable promise/prefer-await-to-then -- Async functions would return promises with shared, mutable prototypes. */
import type { SecretStorage } from 'markedit-api';
import { withScriptContext } from '../scriptContext';

// Capture built-ins before extensions can replace them
const stringify = JSON.stringify;
const parse = JSON.parse;
const isArray = Array.isArray;
const keys = Object.keys;
const hasOwn = Object.hasOwn;
const StorageError = Error;
const defineProperty = Object.defineProperty;
const apply = Reflect.apply;
const promiseThen = Promise.prototype.then;

// Protect both native replies and returned promises from shared Promise hooks.
// This does not isolate extension code that subsequently consumes a secret.
class StoragePromise<T> extends Promise<T> {}
Object.defineProperties(StoragePromise.prototype, {
  then: { value: promiseThen },
  catch: { value: Promise.prototype.catch },
  finally: { value: Promise.prototype.finally },
});

defineProperty(StoragePromise, Symbol.species, { value: StoragePromise });
Object.freeze(StoragePromise.prototype);
Object.freeze(StoragePromise);

export const secretStorage = withScriptContext((_path, capability): SecretStorage => {
  const bridge = window.webkit?.messageHandlers?.bridge;
  const postMessage = bridge?.postMessage.bind(bridge);

  function request(methodName: string, key: string, value?: string): Promise<unknown> {
    return new StoragePromise<unknown>((resolve, reject) => {
      if (!postMessage) {
        throw new StorageError('Secret storage requires the native MarkEdit app.');
      }

      if (capability === undefined) {
        throw new StorageError('This API requires a script-local MarkEdit instance.');
      }

      if (typeof key !== 'string' || (methodName === 'set' && typeof value !== 'string')) {
        throw new StorageError('Invalid secret storage arguments.');
      }

      // Do not let serialization call an extension-defined Object.prototype.toJSON
      const parameters = { __proto__: null, capability, key, value };
      const response = postMessage({
        __proto__: null,
        moduleName: 'secretStorage',
        methodName,
        parameters: stringify(parameters),
      });

      // Native .then also consults constructor[Symbol.species] when creating its result
      const constructor = { __proto__: null, value: StoragePromise };
      defineProperty(response, 'constructor', constructor);
      apply(promiseThen, response, [resolve, reject]);
    }).then(json => {
      if (typeof json !== 'string') {
        throw new StorageError('Invalid secret storage response.');
      }

      const response: unknown = parse(json);
      if (typeof response !== 'object' || response === null || isArray(response)) {
        throw new StorageError('Invalid secret storage response.');
      }

      if (hasOwn(response, 'error')) {
        const error = (response as { error: unknown }).error;
        throw new StorageError(typeof error === 'string' ? error : 'Invalid secret storage error.');
      }

      if (hasOwn(response, 'value')) {
        return (response as { value: unknown }).value;
      }

      if (keys(response).length !== 0) {
        throw new StorageError('Invalid secret storage response.');
      }

      return undefined;
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
