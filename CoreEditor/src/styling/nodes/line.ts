import { BlockInfo, layer, RectangleMarker } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';
import { buildInnerBorder } from '../builder';
import { almostEqual, getViewportScale } from '../../common/utils';

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
    if (window.config.readOnlyMode) {
      return [];
    }

    const content = editor.contentDOM;
    const lineBlocks: BlockInfo[] = [];
    const ranges = editor.state.selection.ranges;

    // Find out all lines, skip overlapping ranges
    let lastBlockPos = -1;
    for (const range of ranges) {
      const lineBlock = editor.lineBlockAt(range.head);
      if (lineBlock.from > lastBlockPos) {
        lineBlocks.push(lineBlock);
        lastBlockPos = lineBlock.from;
      }
    }

    return lineBlocks.map(lineBock => new Layer(content, lineBock, storage.cachedTheme));
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

  constructor(content: HTMLElement, lineBlock: BlockInfo, private readonly theme?: string) {
    const contentRect = content.getBoundingClientRect();

    // The rect is wider than lineRect, it fills the entire contentDOM
    const rectToDraw = (() => {
      const range = EditorSelection.range(lineBlock.from, lineBlock.to);
      const rects = RectangleMarker.forRange(window.editor, 'cm-md-rectMerger', range);
      if (rects.length === 0) {
        // Invalid RectangleMarker length, might be scrolling
        return new DOMRect(0, 0, 0, 0);
      }

      const scale = getViewportScale();
      const top = rects.reduce((acc, cur) => Math.min(acc, cur.top), 1e9);
      const height = rects.reduce((acc, cur) => acc + cur.height, 0);

      // The rect that is slightly taller than the caret, centered vertically
      return new DOMRect(
        contentRect.left,           // x
        top - rectPadding,          // y
        contentRect.width * scale,  // width
        height + rectPadding * 2,   // height
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
    return this.theme === other.theme &&
    almostEqual(this.rect.x, other.rect.x) &&
    almostEqual(this.rect.y, other.rect.y) &&
    almostEqual(this.rect.width, other.rect.width) &&
    almostEqual(this.rect.height, other.rect.height);
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
