import { Decoration, layer, LayerMarker, RectangleMarker } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';
import { syntaxTree } from '@codemirror/language';
import { NodeType } from '@lezer/common';
import { WhitespacesMarker } from '../../dom/views';
import { calculateFontSize } from './heading';
import { createMarkDeco } from '../matchers/regex';
import { createDecoPlugin } from '../helper';
import { frontMatterRange } from '../../modules/frontMatter';

// Originally learned from: https://github.com/ChromeDevTools/devtools-frontend/blob/main/front_end/ui/components/text_editor/config.ts
const renderTabs = createDecoPlugin(() => {
  return createMarkDeco(/\t/g, match => getOrCreateDeco(match[0]));
});

// We don't use the built-in highlightWhitespace extension,
// because it doesn't take custom font size into account.
//
// In Markdown rendering, we have different font sizes for headers,
// we need to figure out proper font size and set it to the pseudo class.
//
// Also, we use layer-based rendering for whitespaces because <span> elements would make autocorretion features hard to use.
// https://codemirror.net/docs/ref/#view.layer
const renderWhitespaces = layer({
  class: 'cm-visibleSpaceLayer',
  above: true,
  markers(editor) {
    const viewport = editor.viewport;
    const slice = editor.state.doc.sliceString(viewport.from, viewport.to);
    const matches = slice.matchAll(/ +/g);
    const markers: LayerMarker[] = [];

    for (const match of matches) {
      const length = match[0].length;
      if (match.index === undefined || length === 0) {
        continue;
      }

      const index = match.index + viewport.from;
      const rects = RectangleMarker.forRange(editor, 'cm-visibleSpace', EditorSelection.range(index, index + length));
      if (rects.length > 0) {
        const fontSize = getFontSize(index);
        markers.push(new WhitespacesMarker(rects[0], length, fontSize));
      }
    }

    return markers;
  },
  update(update) {
    return update.docChanged || update.viewportChanged;
  },
});

export const invisiblesExtension = [
  renderTabs,
  renderWhitespaces,
];

/**
 * Get or create a deco for given invisible character at a position.
 */
function getOrCreateDeco(invisible: string) {
  const cachedDeco = cachedDecos.get(invisible);
  if (cachedDeco !== undefined) {
    return cachedDeco;
  }

  const newDeco = Decoration.mark({ class: 'cm-visibleTab' });
  cachedDecos.set(invisible, newDeco);
  return newDeco;
}

function getFontSize(pos: number) {
  const range = frontMatterRange();
  if (range !== undefined && pos >= range.from && pos <= range.to) {
    return window.config.fontSize;
  }

  const state = window.editor.state;
  const node = syntaxTree(state).resolve(pos);
  return calculateFontSize(window.config.fontSize, headingLevel(node.type));
}

// https://github.com/codemirror/lang-markdown/blob/main/src/markdown.ts
function headingLevel(type: NodeType) {
  const match = /^(?:ATX|Setext)Heading(\d)$/.exec(type.name);
  return match ? +match[1] : 0;
}

const cachedDecos = new Map<string, Decoration>();
