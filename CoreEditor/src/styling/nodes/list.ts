import { Decoration, layer, RectangleMarker } from '@codemirror/view';
import { createDecoPlugin } from '../helper';
import { createDecos } from '../matchers/lexer';

const canvas = document.createElement('canvas');
const className = 'cm-md-indentedList';

const lineDecoPlugin = createDecoPlugin(() => {
  return createDecos('ListItem', listItem => {
    if (shouldDisablePlugins()) {
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
        style: `
          text-indent: -${indent}px;
          margin-inline-start: ${indent}px;
        `,
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

const activeLineFiller = layer({
  class: 'cm-md-listActiveLine',
  above: false,
  markers: () => {
    if (shouldDisablePlugins()) {
      return [];
    }

    // Fill all active lines that are decorated as indented list
    const lists = [...document.querySelectorAll(`.cm-activeLine.${className}`)] as HTMLElement[];
    return lists.map(list => new BackgroundMarker(list));
  },
  update: update => {
    return update.selectionSet || update.docChanged || update.viewportChanged || update.geometryChanged;
  },
});

/**
 * List item indentation, text is always aligned to bullets for soft breaks.
 */
export const indentedListStyle = [
  lineDecoPlugin,
  activeLineFiller,
];

/**
 * Marker that extends active line background color to fill its parent.
 */
class BackgroundMarker extends RectangleMarker {
  private readonly color: string;

  constructor(anchor: HTMLElement) {
    const rect = anchor.getBoundingClientRect();
    super('cm-md-listActiveBackground', 0, anchor.offsetTop, anchor.offsetLeft, rect.bottom - rect.top);

    const style = getComputedStyle(anchor);
    this.color = style.backgroundColor;
  }

  draw() {
    const elt = super.draw();
    elt.style.backgroundColor = this.color;
    return elt;
  }
}

function shouldDisablePlugins() {
  // Indented style is meaningful only when line wrapping is enabled
  return !window.config.lineWrapping;
}

function getTextIndent(text: string) {
  const font = `${window.config.fontSize}px ${window.config.fontFamily}`;
  const key = text + font;
  const cached = widthCache[key];
  if (cached) {
    return cached;
  }

  const context = canvas.getContext('2d') as CanvasRenderingContext2D;
  context.font = font;

  const metrics = context.measureText(text);
  widthCache[key] = metrics.width;
  return metrics.width;
}

const widthCache: { [key: string]: number } = {};
