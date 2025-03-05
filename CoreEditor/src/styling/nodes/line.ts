import { BlockInfo, layer, RectangleMarker } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';
import { almostEqual, getViewportScale } from '../../common/utils';

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

    return lineBlocks.map(lineBock => new Layer(content, lineBock));
  },
  update: update => {
    return update.selectionSet || update.docChanged || update.viewportChanged || update.geometryChanged;
  },
});

class Layer extends RectangleMarker {
  // Used for object equality
  private readonly rect: DOMRect;

  constructor(content: HTMLElement, lineBlock: BlockInfo) {
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
      const height = rects.reduce((acc, cur) => Math.max(acc, cur.top + cur.height), -1e9) - top;

      const left = (() => {
        if (window.config.lineWrapping) {
          return contentRect.left;
        }

        // The content can be horizontally scrolled
        const gutter = document.querySelector('.cm-gutters');
        if (gutter === null) {
          return 0;
        }

        // Use the gutter width
        const style = getComputedStyle(gutter);
        return gutter.getBoundingClientRect().width + parseFloat(style.marginLeft) + parseFloat(style.marginRight);
      })();

      // The rect that is slightly taller than the caret, centered vertically
      return new DOMRect(
        left,                       // x
        top - rectPadding,          // y
        contentRect.width * scale,  // width
        height + rectPadding * 2,   // height
      );
    })();

    super(layerClass, rectToDraw.left, rectToDraw.top, rectToDraw.width, rectToDraw.height);
    this.rect = rectToDraw;
  }

  eq(other: Layer): boolean {
    return almostEqual(this.rect.x, other.rect.x) &&
    almostEqual(this.rect.y, other.rect.y) &&
    almostEqual(this.rect.width, other.rect.width) &&
    almostEqual(this.rect.height, other.rect.height);
  }
}
