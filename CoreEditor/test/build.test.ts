import { describe, expect, test } from '@jest/globals';
import fs from 'fs';
import path from 'path';

const fileNames = [
  '../dist/index.html',
  '../src/@light/dist/index.html',
];

const readHtml = (fileName: string) => {
  const filePath = path.join(__dirname, fileName);
  return fs.readFileSync(filePath, 'utf-8');
};

describe('Build system', () => {
  test('test existence of magic variables', () => {
    fileNames.forEach(fileName => {
      expect(readHtml(fileName)).toContain('"{{EDITOR_CONFIG}}"');
    });
  });

  test('test everything is inlined in a single file', () => {
    fileNames.forEach(fileName => {
      const html = readHtml(fileName);
      expect(html).not.toMatch(/<script[^>]*\ssrc=/i);
      expect(html).not.toMatch(/<link[^>]*\srel=["']?stylesheet/i);
      expect(html).not.toContain('chunk-loader');
    });
  });
});
