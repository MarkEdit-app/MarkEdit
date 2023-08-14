import { RectangleMarker, layer } from '@codemirror/view';
import { buildInnerBorder } from '../builder';

const borderWidth = 2.5;

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

    // We use box shadow to draw inner borders, use an inset to hide the left and right borders
    const borderInset = (() => {
      if (window.colors?.lineBorder === undefined) {
        return 0;
      }

      // Slightly bigger to avoid precision issues
      return borderWidth + 1;
    })();

    // The rect is wider than lineRect, it fills the entire contentDOM
    const rectToDraw = new DOMRect(
      contentRect.left - borderInset,       // x
      line.offsetTop,                       // y
      contentRect.width + borderInset * 2,  // width
      lineRect.height,                      // height
    );

    super('cm-md-activeIndicator', rectToDraw.left, rectToDraw.top, rectToDraw.width, rectToDraw.height);
    this.rect = rectToDraw;
  }

  draw() {
    const elt = super.draw();
    this.render(elt);
    return elt;
  }

  update(elt: HTMLElement, prev: Layer): boolean {
    this.render(elt);
    return super.update(elt, prev);
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

  private render(elt: HTMLElement) {
    const colors = window.colors;
    elt.style.backgroundColor = colors?.activeLine ?? '';
    elt.style.boxShadow = buildInnerBorder(borderWidth, colors?.lineBorder);
  }
}

const storage: {
  cachedTheme?: string;
} = {
  cachedTheme: undefined,
};
