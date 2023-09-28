import { RectangleMarker, layer } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';
import { buildInnerBorder } from '../builder';

const borderWidth = 2.5;
const rectPadding = 2.0;
const layerClass = 'cm-md-activeIndicator';

/**
 * Line level indentations make the background of active lines partially drawn,
 * use this home-made version to have full-width indicators.
 *
 * It just finds all active lines and creates wider layers to "replace" them.
 */
export const lineIndicatorLayer = layer({
  class: 'cm-md-activeLine',
  above: false,
  markers: editor => {
    // Fail fast if line indicator is disabled
    if (!window.config.showActiveLineIndicator) {
      return [];
    }

    const content = editor.contentDOM;
    const lines = [...content.querySelectorAll('.cm-activeLine')] as HTMLElement[];
    return lines.map(line => new Layer(content, line, storage.cachedTheme));
  },
  update: update => {
    // Theme changed, the update object doesn't have sufficient info
    if (window.config.theme !== storage.cachedTheme) {
      // The layer doesn't redraw without this, we haven't figured out the reason...
      const layers = document.querySelectorAll(`.${layerClass}`);
      layers.forEach(layer => layer.remove());

      storage.cachedTheme = window.config.theme;
      return true;
    }

    return update.selectionSet || update.docChanged || update.viewportChanged || update.geometryChanged;
  },
});

class Layer extends RectangleMarker {
  // Used for object equality
  private readonly rect: DOMRect;

  constructor(content: HTMLElement, line: HTMLElement, private readonly theme?: string) {
    const lineRect = line.getBoundingClientRect();
    const contentRect = content.getBoundingClientRect();

    // The rect is wider than lineRect, it fills the entire contentDOM
    const rectToDraw = (() => {
      // The rect that is computed based on element positions, can have precision issues
      const fuzzyRect = new DOMRect(
        contentRect.left,   // x
        line.offsetTop,     // y
        contentRect.width,  // width
        lineRect.height,    // height
      );

      const editor = window.editor;
      const startPos = editor.posAtCoords(lineRect);
      if (startPos === null) {
        return fuzzyRect;
      }

      const endPos = editor.state.doc.lineAt(startPos).to;
      const rects = RectangleMarker.forRange(editor, 'cm-md-rectMerger', EditorSelection.range(startPos, endPos));
      if (rects.length === 0) {
        return fuzzyRect;
      }

      // Unfortunately, geometry values are marked private in RectangleMarker.
      //
      // We access them forcibly and ensure their existence with tests.
      //
      // eslint-disable-next-line no-prototype-builtins
      if (!rects[0].hasOwnProperty('top') || !rects[0].hasOwnProperty('height')) {
        return fuzzyRect;
      }

      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const top = rects.reduce((acc, cur) => Math.min(acc, (cur as any).top as number), 1e9);
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const height = rects.reduce((acc, cur) => acc + (cur as any).height as number, 0);

      // The rect that is more accurate, it is always center aligned to the caret
      return new DOMRect(
        contentRect.left,         // x
        top - rectPadding,        // y
        contentRect.width,        // width
        height + rectPadding * 2, // height
      );
    })();

    super(layerClass, rectToDraw.left, rectToDraw.top, rectToDraw.width, rectToDraw.height);
    this.rect = rectToDraw;
  }

  draw() {
    const element = super.draw();
    this.updateColors(element);
    return element;
  }

  update(element: HTMLElement, prev: Layer): boolean {
    this.updateColors(element);
    return super.update(element, prev);
  }

  eq(other: Layer): boolean {
    const almostEq = (a: number, b: number): boolean => {
      return Math.abs(a - b) < 0.001;
    };

    return this.theme === other.theme &&
    almostEq(this.rect.x, other.rect.x) &&
    almostEq(this.rect.y, other.rect.y) &&
    almostEq(this.rect.width, other.rect.width) &&
    almostEq(this.rect.height, other.rect.height);
  }

  private updateColors(element: HTMLElement) {
    const colors = window.colors;
    element.style.backgroundColor = colors?.activeLine ?? '';
    element.style.boxShadow = buildInnerBorder(borderWidth, colors?.lineBorder);
  }
}

const storage: {
  cachedTheme?: string;
} = {
  cachedTheme: undefined,
};
