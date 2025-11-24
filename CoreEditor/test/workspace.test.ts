import { describe, expect, test } from '@jest/globals';
import { sayHello, getVersion } from 'markedit-hello';

describe('Workspace test suite', () => {
  test('test workspace package exports', () => {
    expect(sayHello).toBeDefined();
    expect(getVersion).toBeDefined();
  });

  test('test workspace package sayHello function', () => {
    expect(sayHello()).toBe('Hello, World! Welcome to MarkEdit.');
    expect(sayHello('Developer')).toBe('Hello, Developer! Welcome to MarkEdit.');
  });

  test('test workspace package getVersion function', () => {
    expect(getVersion()).toBe('1.0.0');
  });
});
