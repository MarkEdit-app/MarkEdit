import { describe, expect, test } from '@jest/globals';
import fs from 'fs';
import path from 'path';

describe('Build system', () => {
  test('test existence of editor config', () => {
    const testFileName = (fileName: string) => {
      const html = fs.readFileSync(path.join(__dirname, fileName), 'utf-8');
      expect(html).toContain('"{{EDITOR_CONFIG}}"');
    };

    testFileName('../dist/index.html');
    testFileName('../src/@light/dist/index.html');
  });
});
