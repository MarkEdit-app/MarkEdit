import { describe, expect, test } from '@jest/globals';
import { EditorView } from '@codemirror/view';
import { Config } from '../src/config';
import { setFontFace, setFontSize } from '../src/modules/config';

describe('Config module', () => {
  test('updates font settings before the editor is initialized', () => {
    window.editor = document.createElement('div') as unknown as EditorView;
    window.config = {
      fontFace: { family: 'ui-monospace' },
      fontSize: 15,
      showLineNumbers: false,
    } as Config;

    expect(() => setFontFace({ family: 'system-ui' })).not.toThrow();
    expect(() => setFontSize(18)).not.toThrow();
    expect(window.config.fontFace).toEqual({ family: 'system-ui' });
    expect(window.config.fontSize).toBe(18);
  });
});
