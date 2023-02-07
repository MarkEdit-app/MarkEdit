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
