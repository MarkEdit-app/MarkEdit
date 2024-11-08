import { createMarkDeco, createWidgetDeco, createLineDeco } from '../matchers/lezer';
import { createDecoPlugin } from '../helper';
import { PreviewWidget } from '../views';
import { cancelDefaultEvent, PreviewType, showPreview } from '../../modules/preview';

/**
 * Always use monospace font for InlineCode.
 */
export const inlineCodeStyle = createDecoPlugin(() => {
  return createMarkDeco('InlineCode', 'cm-md-monospace cm-md-inlineCode');
});

/**
 * Always use monospace font for FencedCode.
 */
export const codeBlockStyle = createDecoPlugin(() => {
  return createLineDeco(['FencedCode', 'CodeBlock'], 'cm-md-monospace cm-md-codeBlock', {
    'spellcheck': 'false',
    'autocorrect': 'off',
    'autocomplete': 'off',
    'autocapitalize': 'off',
  });
});

/**
 * Enable [preview] button for https://mermaid.js.org/.
 */
export const previewMermaid = createDecoPlugin(() => {
  return createWidgetDeco('CodeInfo', node => {
    const state = window.editor.state;
    if (state.sliceDoc(node.from, node.to) !== 'mermaid') {
      return null;
    }

    const container = node.node.parent;
    if (container === null || container.name !== 'FencedCode') {
      return null;
    }

    const boundary = container.lastChild;
    if (boundary === null || boundary.name !== 'CodeMark') {
      return null;
    }

    const code = state.sliceDoc(node.to + 1, boundary.from);
    if (code.trim().length === 0) {
      return null;
    }

    // Here we finally confirmed that the code block is for mermaid
    return new PreviewWidget(code, PreviewType.mermaid, node.to);
  });
}, {
  click: showPreview,
  mousedown: cancelDefaultEvent,
});

/**
 * Enable [preview] button for https://katex.org/.
 */
export const previewMath = createDecoPlugin(() => {
  return createWidgetDeco('BlockMath', node => {
    const state = window.editor.state;
    const code = state.sliceDoc(node.from + 2, node.to - 2); // 2 is the length of "$$"
    if (code.trim().length === 0) {
      return null;
    }

    return new PreviewWidget(code, PreviewType.katex, node.from + 2);
  });
}, {
  click: showPreview,
  mousedown: cancelDefaultEvent,
});
