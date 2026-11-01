import { describe, expect, test } from '@jest/globals';
import path from 'path';
import { renderCode } from 'ts-gyb/dist/renderer/renderer';

const render = (methods: object[]) => renderCode(
  path.join(__dirname, '../src/@codegen/swift-native-module.mustache'),
  {
    moduleName: 'NativeModuleTest',
    customTags: { bridgeName: 'NativeBridgeTest', invokePath: 'test' },
    methods,
  },
);

describe('Native bridge generation', () => {
  test('shares parameter decoding while keeping typed locals and error handling', () => {
    const result = render([{
      methodName: 'translate',
      returnType: 'String',
      parameters: [
        { name: 'text', type: 'String' },
        { name: 'from', type: 'String?', last: true },
      ],
    }]);

    expect(result).toContain('decoder.decode(BridgeParameters.self, from: parameters).container');
    expect(result).toContain('let parameter_text: String');
    expect(result).toContain('let parameter_from: String?');
    expect(result).toContain('parameter_from = try container.value("from")');
    expect(result).not.toContain('struct Message');
    expect(result).toContain('Logger.assertFail("Failed to decode parameters: \\(parameters)")');
    expect(result).toContain('return .failure(error)');
    expect(result).toContain('let result = await module.translate(text: parameter_text, from: parameter_from)');
    expect(result.indexOf('parameter_from =')).toBeLessThan(result.indexOf('await module.translate'));
    expect(result).toContain('return .success(result)');
  });

  test('keeps zero-argument methods and unknown-method behavior unchanged', () => {
    const result = render([{ methodName: 'cancel', parameters: [] }]);
    expect(result).toContain('switch method {');
    expect(result).toContain('default:\n      return nil');
    expect(result).toContain('module.cancel()');
    expect(result).toContain('return .success(nil)');
    expect(result).not.toContain('decoder.decode(');
  });

  test('does not shadow bridge locals when parameter names overlap', () => {
    const names = ['parameters', 'module', 'decoder', 'container', 'result'];
    const result = render([{
      methodName: 'update',
      parameters: names.map((name, index) => ({ name, type: 'String', last: index === names.length - 1 })),
    }]);

    for (const name of names) {
      expect(result).toContain(`let parameter_${name}: String`);
      expect(result).toContain(`parameter_${name} = try container.value("${name}")`);
      expect(result).toContain(`${name}: parameter_${name}`);
    }
  });

  test.each([false, true])('only result-returning helpers are async (with arguments: %s)', (hasParameters) => {
    const parameters = hasParameters ? [{ name: 'text', type: 'String', last: true }] : [];
    const result = render([
      { methodName: 'notify', parameters },
      { methodName: 'fetch', returnType: 'String?', parameters },
    ]);

    expect(result).toContain('func invoke(method: String, parameters: Data) async -> Result<Any?, Error>?');
    expect(result).toContain('@MainActor\nfinal class NativeBridgeTest');
    expect(result).toContain('return notify(parameters: parameters)');
    expect(result).toContain('private func notify(parameters: Data) -> Result<Any?, Error>?');
    expect(result).not.toContain('await notify(');
    expect(result).not.toContain('await module.notify(');
    expect(result).toContain('return await fetch(parameters: parameters)');
    expect(result).toContain('private func fetch(parameters: Data) async -> Result<Any?, Error>?');
    expect(result).toContain('let result = await module.fetch(');
  });
});
