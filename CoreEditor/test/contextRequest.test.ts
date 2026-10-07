import { beforeEach, describe, expect, jest, test } from '@jest/globals';
import { createContextRequest } from '../src/bridge/contextRequest';

const postMessage = jest.fn<(message: {
  moduleName: string;
  methodName: string;
  parameters: string;
}) => Promise<unknown>>();

beforeEach(() => {
  postMessage.mockReset();
  postMessage.mockResolvedValue('{"value":true}');
  window.webkit = { messageHandlers: { bridge: { postMessage } } };
});

describe('context request', () => {
  test('binds different modules and capabilities and serializes primitive fields', async () => {
    const first = createContextRequest('firstModule', 'first-capability');
    const second = createContextRequest('secondModule', 'second-capability');
    await expect(first('perform', () => ({ text: 'value', flag: true, count: 2, empty: null, omitted: undefined })))
      .resolves.toBe(true);
    await expect(second('read', () => ({}))).resolves.toBe(true);

    expect(postMessage.mock.calls.map(([message]) => ({
      ...message, parameters: JSON.parse(message.parameters),
    }))).toEqual([
      {
        moduleName: 'firstModule',
        methodName: 'perform',
        parameters: { capability: 'first-capability', text: 'value', flag: true, count: 2, empty: null },
      },
      { moduleName: 'secondModule', methodName: 'read', parameters: { capability: 'second-capability' } },
    ]);

    expect(Object.getPrototypeOf(postMessage.mock.calls[0][0])).toBeNull();
  });

  test('rejects preparation failures without invoking native', async () => {
    const request = createContextRequest('test', 'capability');
    const error = new Error('Invalid API arguments');
    await expect(request('read', () => { throw error; })).rejects.toBe(error);
    expect(postMessage).not.toHaveBeenCalled();
  });

  test('rejects missing context or host before preparing parameters', async () => {
    const prepare = jest.fn(() => ({}));
    await expect(createContextRequest('test')('read', prepare)).rejects.toThrow('script-local MarkEdit');
    window.webkit = undefined;
    await expect(createContextRequest('test', 'capability')('read', prepare)).rejects.toThrow('native MarkEdit app');
    expect(prepare).not.toHaveBeenCalled();
    expect(postMessage).not.toHaveBeenCalled();
  });

  test('rejects capability overrides, accessors, and non-finite numbers', async () => {
    const request = createContextRequest('test', 'capability');
    const getter = jest.fn(() => 'secret');
    const accessor = Object.defineProperty({}, 'key', { get: getter, enumerable: true });
    for (const parameters of [{ capability: 'forged' }, accessor, { count: NaN }, { count: Infinity }]) {
      await expect(request('read', () => parameters)).rejects.toThrow('Invalid contextual native parameters');
    }

    expect(getter).not.toHaveBeenCalled();
    expect(postMessage).not.toHaveBeenCalled();
  });

  test('rejects nested values without invoking serialization hooks', async () => {
    const request = createContextRequest('test', 'capability');
    const toJSON = jest.fn(() => 'secret');
    // @ts-expect-error Structured parameters are deliberately unsupported.
    await expect(request('read', () => ({ nested: { toJSON } }))).rejects.toThrow('Invalid contextual native parameters');
    expect(toJSON).not.toHaveBeenCalled();
    expect(postMessage).not.toHaveBeenCalled();
  });

  test('rejects non-string native replies', async () => {
    const request = createContextRequest('test', 'capability');
    for (const response of [undefined, null, false, 1, {}]) {
      postMessage.mockResolvedValueOnce(response);
      await expect(request('read', () => ({}))).rejects.toThrow('Invalid contextual native response');
    }
  });

  test.each([
    ['{}', undefined],
    ['{"value":null}', null],
    ['{"value":false}', false],
    ['{"value":0}', 0],
    ['{"value":""}', ''],
    ['{"value":"secret"}', 'secret'],
  ])('decodes the primitive envelope %s', async (json, value) => {
    postMessage.mockResolvedValueOnce(json);
    await expect(createContextRequest('test', 'capability')('read', () => ({}))).resolves.toBe(value);
  });

  test.each(['null', '[]', 'true', '"text"', '{"unexpected":true}', '{"value":[]}', '{"value":{}}', '{"value":1e400}'])(
    'rejects invalid envelopes or values: %s', async json => {
      postMessage.mockResolvedValueOnce(json);
      await expect(createContextRequest('test', 'capability')('read', () => ({})))
        .rejects.toThrow('Invalid contextual native');
    },
  );

  test('propagates native errors and rejects malformed JSON and error fields', async () => {
    const request = createContextRequest('test', 'capability');
    postMessage.mockResolvedValueOnce('{"error":"Access cancelled","value":"ignored"}');
    await expect(request('read', () => ({}))).rejects.toThrow('Access cancelled');
    postMessage.mockResolvedValueOnce('{"error":{}}');
    await expect(request('read', () => ({}))).rejects.toThrow('Invalid contextual native error');
    postMessage.mockResolvedValueOnce('{');
    await expect(request('read', () => ({}))).rejects.toBeInstanceOf(SyntaxError);
  });

  test('rejects object results before inherited then hooks can observe them', async () => {
    const request = createContextRequest('test', 'capability');
    postMessage.mockResolvedValueOnce('{"value":{"secret":"private-secret"}}');

    const original = Object.getOwnPropertyDescriptor(Object.prototype, 'then');
    const observed: unknown[] = [];
    Object.defineProperty(Object.prototype, 'then', {
      configurable: true,
      get(this: object) {
        if (Object.hasOwn(this, 'secret')) {
          observed.push(this);
        }
        return undefined;
      },
    });

    try {
      await expect(request('read', () => ({}))).rejects.toThrow('Invalid contextual native value');
    } finally {
      if (original) {
        Object.defineProperty(Object.prototype, 'then', original);
      } else {
        Reflect.deleteProperty(Object.prototype, 'then');
      }
    }

    expect(observed).toEqual([]);
  });
});
