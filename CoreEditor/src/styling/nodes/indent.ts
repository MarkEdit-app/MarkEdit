import { Decoration } from '@codemirror/view';
import { createDecoPlugin } from '../helper';
import { createDecos } from '../matchers/lezer';

const canvas = document.createElement('canvas');
const className = 'cm-md-contentIndent';

/**
 * Content indentation for lists and blockquotes, content is always aligned to marks for soft breaks.
 */
export const contentIndentStyle = createDecoPlugin(() => {
  return createDecos(['ListMark', 'QuoteMark'], markNode => {
    // Fail fast if line wrapping is disabled
    if (!window.config.lineWrapping) {
      return null;
    }

    const editor = window.editor;
    const line = editor.state.doc.lineAt(markNode.from);
    const text = line.text;

    // For example: " 1.  Hello",
    // we need to find the position of the last whitespace before "H".
    //
    // As a result, we will use " 1.  " to calculate the indent.
    let index = markNode.to - line.from;
    while (text.charAt(index) === ' ' && index < text.length) {
      ++index;
    }

    const indent = getTextIndent(text.substring(0, index));
    const deco = Decoration.line({
      class: className,
      attributes: {
        style: `text-indent: -${indent}; margin-inline-start: ${indent};`,
      },
    });

    // Remember to use line decoration instead of mark decoration,
    // see: https://discuss.codemirror.net/t/6968
    //
    // Another reason is that items can be nested, take the following example:
    //  - Hello
    //    - World
    //
    // When iterating through "Hello", the itemNode contains "World" too.
    // Over-decorating "World" could arise if we used node ranges to create mark decorations,
    // and remember that node ranges exclude leading spaces.
    //
    // Instead, use line ranges to create line decorations for the current line,
    // because items are separated by line breaks.
    return deco.range(line.from, line.from);
  });
});

function getTextIndent(text: string) {
  const font = `${window.config.fontSize}px ${window.config.fontFace.family}`;
  const key = text + font;
  const cachedValue = storage.cachedIndents[key];
  if (cachedValue) {
    return cachedValue;
  }

  const width = (() => {
    if (measurableFonts().includes(window.config.fontFace.family)) {
      return measureTextPreferred(text, font);
    } else {
      return measureTextFallback(text, font);
    }
  })();

  storage.cachedIndents[key] = width;
  return width;
}

function measureTextPreferred(text: string, font: string) {
  // Preferred approach, works for built-in fonts
  const context = canvas.getContext('2d') as CanvasRenderingContext2D;
  context.font = font;

  const width = context.measureText(text).width;
  return `${width}px`;
}

function measureTextFallback(text: string, font: string) {
  // It's similar to context.measureText, with an actual element created to fit more fonts
  const element = document.createElement('div');
  element.style.position = 'absolute';
  element.style.visibility = 'hidden';
  element.style.left = '-9999px';
  element.style.font = font;
  element.innerText = text.replace(/ /g, '\u00a0'); // &nbsp;

  document.body.appendChild(element);
  const width = getComputedStyle(element).width; // This value is rounded

  document.body.removeChild(element);
  return width;
}

function measurableFonts() {
  // measureText doesn't work well with some fonts, e.g., Iosevka
  return [
    'SF Mono',
    'monospace',
    'system-ui',
    'ui-monospace',
    'ui-rounded',
    'ui-serif',
  ];
}

const storage: {
  cachedIndents: { [key: string]: string };
} = {
  cachedIndents: {},
};
