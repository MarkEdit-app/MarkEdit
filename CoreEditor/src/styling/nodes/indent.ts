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
    if (useCanvas(text, window.config.fontFace.family)) {
      return measureTextCanvas(text, font);
    } else {
      return measureTextDOM(text, font);
    }
  })();

  storage.cachedIndents[key] = width;
  return width;
}

function measureTextCanvas(text: string, font: string) {
  // Preferred approach, works for most cases
  const context = canvas.getContext('2d') as CanvasRenderingContext2D;
  context.font = font;

  const width = context.measureText(text).width;
  return `${width}px`;
}

function measureTextDOM(text: string, font: string) {
  // It's similar to context.measureText, with an actual element created to fit more scenarios
  const element = document.createElement('pre'); // Use <pre> to preserve spaces and tabs
  element.style.tabSize = `${window.editor.state.tabSize}`;
  element.style.position = 'absolute';
  element.style.visibility = 'hidden';
  element.style.left = '-9999px';
  element.style.font = font;
  element.innerText = text;

  document.body.appendChild(element);
  const width = getComputedStyle(element).width; // This value is rounded

  document.body.removeChild(element);
  return width;
}

function useCanvas(text: string, font: string) {
  // context.measureText doesn't work well with some fonts (like Iosevka), or when the content has tabs
  return [
    'SF Mono',
    'monospace',
    'system-ui',
    'ui-monospace',
    'ui-rounded',
    'ui-serif',
  ].includes(font) && !text.includes('\t');
}

const storage: {
  cachedIndents: { [key: string]: string };
} = {
  cachedIndents: {},
};
