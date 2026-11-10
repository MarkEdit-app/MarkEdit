import { EditorView, ViewPlugin } from '@codemirror/view';

export const typewriterPadding = ViewPlugin.fromClass(class {
  constructor(private readonly view: EditorView) {
    this.update();
  }

  update() {
    if (!window.config.typewriterMode) {
      this.view.contentDOM.style.removeProperty('--typewriter-bottom-padding');
      return;
    }

    this.view.requestMeasure({
      key: this,
      read: view => {
        const caret = view.coordsAtPos(view.state.doc.length);
        if (caret === null) {
          // The last line may be outside CodeMirror's rendered viewport
          return undefined;
        }

        const content = view.contentDOM;
        const padding = parseFloat(getComputedStyle(content).paddingBottom);
        const caretCenter = (caret.top + caret.bottom) / 2;
        const scroller = view.scrollDOM;

        // Exclude the current padding so maximum scroll centers the final caret
        const belowCaret = (content.getBoundingClientRect().bottom - caretCenter) / view.scaleY - padding;
        const targetOffset = scroller.scrollTop + (caretCenter - scroller.getBoundingClientRect().top) / view.scaleY - scroller.clientHeight / 2;

        // WebKit truncates scrollTop but rounds scrollHeight; keep the bottom at the lower integer offset
        const rounding = targetOffset - Math.floor(targetOffset);
        return Math.max(0, scroller.clientHeight / 2 - belowCaret - rounding);
      },
      write: padding => {
        if (padding === undefined || !window.config.typewriterMode) {
          return;
        }

        const style = this.view.contentDOM.style;
        const previous = parseFloat(style.getPropertyValue('--typewriter-bottom-padding'));
        if (Math.abs(previous - padding) < 0.01) {
          return;
        }

        style.setProperty('--typewriter-bottom-padding', `${padding}px`);
      },
    });
  }
});
