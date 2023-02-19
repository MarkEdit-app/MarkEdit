import { RectangleMarker } from '@codemirror/view';
import { WidgetView } from './types';
import { PreviewType } from '../../modules/preview';

/**
 * Widget used to show a [preview] button after some contents, such as mermaid diagrams.
 */
export class PreviewWidget extends WidgetView {
  constructor(private readonly code: string, private readonly type: PreviewType, pos: number) {
    super();
    this.pos = pos;
  }

  toDOM() {
    const span = document.createElement('span');
    span.style.paddingLeft = '4px';

    // Only include paddingRight for katext because it can be inline
    if (this.type == PreviewType.katex) {
      span.style.paddingRight = '4px';
    }

    const button = span.appendChild(document.createElement('span'));
    button.setAttribute('data-code', this.code);
    button.setAttribute('data-type', this.type);
    button.setAttribute('data-pos', `${this.pos}`);

    button.innerText = `[${window.config.localizable?.previewButtonTitle}]`;
    button.className = 'cm-md-previewButton';

    return span;
  }

  eq(other: PreviewWidget) {
    return other.code === this.code && other.type === this.type && other.pos === this.pos;
  }

  ignoreEvent() {
    return false;
  }
}

/**
 * RectangleMarker that generates elements to render visible whitespaces.
 */
export class WhitespacesMarker extends RectangleMarker {
  // It would be great if we had "attributes" available in RectangleMarker,
  // here we access private properties to recreate a marker.
  //
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  constructor(rect: any, private readonly length: number, private readonly fontSize: number) {
    super('cm-visibleSpace', rect.left as number, rect.top as number, rect.width as number, rect.height as number);
  }

  draw() {
    const elt = super.draw();
    this.render(elt);
    return elt;
  }

  update(elt: HTMLElement, prev: RectangleMarker): boolean {
    this.render(elt);
    return super.update(elt, prev);
  }

  eq(other: WhitespacesMarker): boolean {
    return super.eq(other) && this.length === other.length && this.fontSize === other.fontSize;
  }

  private render(elt: HTMLElement) {
    elt.setAttribute('content', '·‌'.repeat(this.length));

    // Only enable special style for Markdown headings where bigger font sizes are used
    if (this.fontSize > window.config.fontSize) {
      elt.style.fontSize = `${this.fontSize}px`;
    }
  }
}
