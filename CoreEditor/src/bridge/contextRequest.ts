/* eslint-disable promise/prefer-await-to-then -- Async functions would return promises with shared, mutable prototypes. */
const stringify = JSON.stringify;
const parse = JSON.parse;
const isArray = Array.isArray;
const keys = Object.keys;
const getOwnPropertyDescriptor = Object.getOwnPropertyDescriptor;
const hasOwn = Object.hasOwn;
const isFinite = Number.isFinite;
const RequestError = Error;
const defineProperty = Object.defineProperty;
const apply = Reflect.apply;
const promiseThen = Promise.prototype.then;
type Primitive = string | boolean | number | null | undefined;

class ContextualPromise<T> extends Promise<T> {}
Object.defineProperties(ContextualPromise.prototype, {
  then: { value: promiseThen },
  catch: { value: Promise.prototype.catch },
  finally: { value: Promise.prototype.finally },
});

defineProperty(ContextualPromise, Symbol.species, { value: ContextualPromise });
Object.freeze(ContextualPromise.prototype);
Object.freeze(ContextualPromise);

/**
 * Prepare before extensions run; native modules must validate the capability.
 * Build parameter objects internally. Only primitive fields and results are supported.
 * Use .then, not async wrappers, to preserve Promise protection.
 * Protects transport, not code consuming the result.
 */
export function createContextRequest(moduleName: string, capability?: string) {
  const bridge = window.webkit?.messageHandlers?.bridge;
  const postMessage = bridge?.postMessage.bind(bridge);

  return (methodName: string, prepareParameters: () => Record<string, Primitive>): Promise<Primitive> =>
    new ContextualPromise<string>((resolve, reject) => {
      if (!postMessage) {
        throw new RequestError('This API requires the native MarkEdit app.');
      }

      if (capability === undefined) {
        throw new RequestError('This API requires a script-local MarkEdit instance.');
      }

      const parameters = prepareParameters();
      const names = keys(parameters);
      const payload: Record<string, Primitive> = { __proto__: null, capability };

      for (let index = 0; index < names.length; index += 1) {
        const name = names[index];
        const descriptor = getOwnPropertyDescriptor(parameters, name);
        if (name === 'capability' || !descriptor || !hasOwn(descriptor, 'value')) {
          throw new RequestError('Invalid contextual native parameters.');
        }

        const value: unknown = descriptor.value;
        if (!isPrimitive(value)) {
          throw new RequestError('Invalid contextual native parameters.');
        }

        payload[name] = value;
      }

      // Null prototypes prevent inherited setters and toJSON hooks from observing parameters
      const response = postMessage({
        __proto__: null,
        moduleName,
        methodName,
        parameters: stringify(payload),
      });

      // Native .then consults constructor[Symbol.species] when creating its result
      const constructor = { __proto__: null, value: ContextualPromise };
      defineProperty(response, 'constructor', constructor);
      apply(promiseThen, response, [(json: unknown) => {
        if (typeof json !== 'string') {
          reject(new RequestError('Invalid contextual native response.'));
        } else {
          resolve(json);
        }
      }, reject]);
    }).then(decodeResponse);
}

function decodeResponse(json: string): Primitive {
  const response: unknown = parse(json);
  if (typeof response !== 'object' || response === null || isArray(response)) {
    throw new RequestError('Invalid contextual native response.');
  }

  if (hasOwn(response, 'error')) {
    const error = (response as { error: unknown }).error;
    throw new RequestError(typeof error === 'string' ? error : 'Invalid contextual native error.');
  }

  if (hasOwn(response, 'value')) {
    const value = (response as { value: unknown }).value;
    // Reject objects before Promise resolution can consult an inherited then hook
    if (!isPrimitive(value)) {
      throw new RequestError('Invalid contextual native value.');
    }

    return value;
  }

  if (keys(response).length !== 0) {
    throw new RequestError('Invalid contextual native response.');
  }

  return undefined;
}

function isPrimitive(value: unknown): value is Primitive {
  return value === null || value === undefined || typeof value === 'string'
    || typeof value === 'boolean' || (typeof value === 'number' && isFinite(value));
}
