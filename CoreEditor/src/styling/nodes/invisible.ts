import { Decoration } from '@codemirror/view';
import { syntaxTree } from '@codemirror/language';
import { NodeType } from '@lezer/common';
import { calculateFontSize } from './heading';
import { createMarkDeco } from '../matchers/regex';
import { createDecoPlugin } from '../helper';

// Originally learned from: https://github.com/ChromeDevTools/devtools-frontend/blob/main/front_end/ui/components/text_editor/config.ts
//
// We don't use the built-in highlightWhitespace extension,
// because it doesn't take custom font size into account.
//
// In Markdown rendering, we have different font sizes for headers,
// we need to figure out proper font size and set it to the pseudo class.
export const invisiblesExtension = createDecoPlugin(() => {
  return createMarkDeco(/\t| +/g, (match, pos) => {
    const invisible = match[0];
    return getOrCreateDeco(invisible, pos);
  });
});

/**
 * Get or create a deco for given invisible character at a position.
 */
function getOrCreateDeco(invisible: string, pos: number) {
  const state = window.editor.state;
  const node = syntaxTree(state).resolve(pos);

  const fontSize = calculateFontSize(window.config.fontSize, headingLevel(node.type));
  const key = invisible + fontSize;
  const cachedDeco = cachedDecos.get(key);

  // Great, exactly the same deco was created before
  if (cachedDeco !== undefined) {
    return cachedDeco;
  }

  const fontStyle = (() => {
    if (fontSize <= window.config.fontSize) {
      // Only enable special style for Markdown headings where bigger font sizes are used
      return '';
    }

    return `font-size: ${fontSize}px`;
  })();

  const newDeco = Decoration.mark({
    attributes: invisible === '\t' ? { 'class': 'cm-visibleTab' } : {
      'class': 'cm-visibleSpace',
      'style': fontStyle,
      'content': '·‌'.repeat(invisible.length),
    },
  });

  cachedDecos.set(key, newDeco);
  return newDeco;
}

// https://github.com/codemirror/lang-markdown/blob/main/src/markdown.ts
function headingLevel(type: NodeType) {
  const match = /^(?:ATX|Setext)Heading(\d)$/.exec(type.name);
  return match ? +match[1] : 0;
}

const cachedDecos = new Map<string, Decoration>();
