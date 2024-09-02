import { describe, expect, test } from '@jest/globals';
import fs from 'fs';
import path from 'path';

describe('Build system', () => {
  test('test existence of magic variables', () => {
    const testFileName = (fileName: string, hasChunks: boolean) => {
      const html = fs.readFileSync(path.join(__dirname, fileName), 'utf-8');
      expect(html).toContain('"{{EDITOR_CONFIG}}"');

      if (hasChunks) {
        expect(html).toContain('/chunk-loader/');
      }
    };

    testFileName('../dist/index.html', true);
    testFileName('../src/@light/dist/index.html', false);
  });
});
