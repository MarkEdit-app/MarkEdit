import { Decoration } from '@codemirror/view';
import { createDecoPlugin } from '../helper';
import { createDecos } from '../matchers/lexer';

const canvas = document.createElement('canvas');
const className = 'cm-md-indentedList';

/**
 * List item indentation, text is always aligned to bullets for soft breaks.
 */
export const indentedListStyle = createDecoPlugin(() => {
  return createDecos('ListItem', listItem => {
    // Fail fast if line wrapping is disabled
    if (!window.config.lineWrapping) {
      return null;
    }

    const listMark = listItem.node.getChild('ListMark');
    if (listMark === null) {
      // Theoretically, this should not happen if the list is valid
      return null;
    }

    const editor = window.editor;
    const line = editor.state.doc.lineAt(listItem.from);
    const text = line.text;

    // For example: " 1.  Hello",
    // we need to find the position of the last whitespace before "H".
    //
    // As a result, we will use " 1.  " to calculate the indent.
    let index = listMark.to - line.from;
    while (text.charAt(index) === ' ' && index < text.length) {
      ++index;
    }

    const indent = getTextIndent(text.substring(0, index));
    const deco = Decoration.line({
      class: className,
      attributes: {
        style: `text-indent: -${indent}px; margin-inline-start: ${indent}px;`,
      },
    });

    // Remember to use line decoration instead of mark decoration,
    // see: https://discuss.codemirror.net/t/6968
    //
    // Another reason is that list items can be nested, take the following example:
    //  - Hello
    //    - World
    //
    // When iterating through "Hello", the listItem node contains "World" too.
    // Over-decorating "World" could arise if we used node ranges to create mark decorations,
    // and remember that node ranges exclude leading spaces.
    //
    // Instead, use line ranges to create line decorations for the current line,
    // because list items are separated by line breaks.
    return deco.range(line.from, line.from);
  });
});

function getTextIndent(text: string) {
  const font = `${window.config.fontSize}px ${window.config.fontFamily}`;
  const key = text + font;
  const cachedValue = storage.cachedIndents[key];
  if (cachedValue) {
    return cachedValue;
  }

  const context = canvas.getContext('2d') as CanvasRenderingContext2D;
  context.font = font;

  const metrics = context.measureText(text);
  storage.cachedIndents[key] = metrics.width;
  return metrics.width;
}

const storage: {
  cachedIndents: { [key: string]: number };
} = {
  cachedIndents: {},
};
