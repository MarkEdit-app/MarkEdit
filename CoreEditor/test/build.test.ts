import { describe, expect, test } from '@jest/globals';
import fs from 'fs';
import path from 'path';

const readHtml = () => {
  const filePath = path.join(__dirname, '../dist/index.html');
  return fs.readFileSync(filePath, 'utf-8');
};

describe('Build system', () => {
  test('magic variables occur once, with config before settings', () => {
    const html = readHtml();
    const config = '"{{EDITOR_CONFIG}}"';
    const settings = '"{{USER_SETTINGS}}"';

    expect(html.split(config)).toHaveLength(2);
    expect(html.split(settings)).toHaveLength(2);
    expect(html.indexOf(config)).toBeLessThan(html.indexOf(settings));
  });

  test('test everything is inlined in a single file', () => {
    const html = readHtml();
    expect(html).not.toMatch(/<script[^>]*\ssrc=/i);
    expect(html).not.toMatch(/<link[^>]*\srel=["']?stylesheet/i);
    expect(html).not.toContain('chunk-loader');
  });
});
