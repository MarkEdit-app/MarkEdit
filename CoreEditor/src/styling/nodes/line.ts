import { RectangleMarker, layer } from '@codemirror/view';
import { buildInnerBorder } from '../builder';

/**
 * Indentations make the active line background partially drawn,
 * use this home-made version to have full-width active line indicator.
 *
 * It just finds all active lines and creates wider layers to replace them.
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
    if (window.config.theme !== storage.cachedTheme) {
      storage.cachedTheme = window.config.theme;
      return true;
    }

    return update.selectionSet || update.docChanged || update.viewportChanged || update.geometryChanged;
  },
});

class Layer extends RectangleMarker {
  // Used to implement the equals function
  private readonly rect: DOMRect;

  constructor(content: HTMLElement, line: HTMLElement, private readonly theme?: string) {
    const lineRect = line.getBoundingClientRect();
    const contentRect = content.getBoundingClientRect();
    super('cm-md-activeIndicator', contentRect.left, line.offsetTop, contentRect.width, lineRect.height);

    this.rect = new DOMRect(
      contentRect.left,   // x
      line.offsetTop,     // y
      contentRect.width,  // width
      lineRect.height,    // height
    );
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
    }

    return this.theme === other.theme &&
    almostEq(this.rect.x, other.rect.x) &&
    almostEq(this.rect.y, other.rect.y) &&
    almostEq(this.rect.width, other.rect.width) &&
    almostEq(this.rect.height, other.rect.height);
  }

  private render(elt: HTMLElement) {
    const colors = window.colors;
    if (colors === undefined) {
      return;
    }

    elt.style.backgroundColor = colors.activeLine;
    elt.style.boxShadow = buildInnerBorder(2.5, colors.lineBorder);
  }
}

const storage: {
  cachedTheme?: string;
} = {
  cachedTheme: undefined,
};
