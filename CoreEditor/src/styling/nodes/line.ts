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
  constructor(content: HTMLElement, line: HTMLElement, private readonly theme?: string) {
    const lineRect = line.getBoundingClientRect();
    const contentRect = content.getBoundingClientRect();
    super('cm-md-activeIndicator', contentRect.left, line.offsetTop, contentRect.width, lineRect.height);
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
    return this.theme === other.theme && super.eq(other);
  }

  private render(elt: HTMLElement) {
    const colors = window.colors;
    if (colors === undefined) {
      return;
    }

    elt.style.backgroundColor = colors.activeLine;
    if (colors.lineBorder !== undefined) {
      elt.style.boxShadow = buildInnerBorder(2.5, colors.lineBorder);
    }
  }
}

const storage: {
  cachedTheme?: string;
} = {
  cachedTheme: undefined,
};
