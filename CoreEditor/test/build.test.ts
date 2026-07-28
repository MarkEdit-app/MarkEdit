import { describe, expect, test } from '@jest/globals';
import fs from 'fs';
import path from 'path';

const readHtml = () => {
  const filePath = path.join(__dirname, '../dist/index.html');
  return fs.readFileSync(filePath, 'utf-8');
};

describe('Build system', () => {
  test('test existence of magic variables', () => {
    const html = readHtml();
    expect(html).toContain('"{{EDITOR_CONFIG}}"');
    expect(html).toContain('"{{USER_SETTINGS}}"');
  });

  test('test everything is inlined in a single file', () => {
    const html = readHtml();
    expect(html).not.toMatch(/<script[^>]*\ssrc=/i);
    expect(html).not.toMatch(/<link[^>]*\srel=["']?stylesheet/i);
    expect(html).not.toContain('chunk-loader');
  });
});
