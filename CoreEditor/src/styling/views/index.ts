import { WidgetView } from './types';
import { PreviewType } from '../../modules/preview';
import { globalState } from '../../common/store';

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
    span.className = 'cm-md-previewWrapper';

    const color = `${globalState.colors?.text ?? '#666666'}20`;
    span.addEventListener('mouseenter', () => span.style.background = color);
    span.addEventListener('mouseleave', () => span.style.background = '');

    const button = span.appendChild(document.createElement('span'));
    button.dataset.code = this.code;
    button.dataset.type = this.type;
    button.dataset.pos = `${this.pos}`;

    button.title = window.config.localizable?.previewButtonTitle ?? '';
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
 * Widget used to render line breaks as visible characters.
 */
export class LineBreakWidget extends WidgetView {
  constructor(pos: number) {
    super();
    this.pos = pos;
  }

  toDOM() {
    const span = document.createElement('span');
    span.className = 'cm-visibleLineBreak';
    span.setAttribute('content', window.config.visibleLineBreakCharacter ?? '¬');
    return span;
  }

  eq(other: LineBreakWidget) {
    return other.pos === this.pos;
  }
}
