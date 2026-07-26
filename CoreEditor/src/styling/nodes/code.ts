import { Decoration } from '@codemirror/view';
import { createBlockWrappers, createDecos, createWidgetDeco, createLineDeco } from '../matchers/lezer';
import { createBlockPlugin, createDecoPlugin } from '../helper';
import { PreviewWidget } from '../views';
import { cancelDefaultEvent, PreviewType, showPreview } from '../../modules/preview';

/**
 * Decorations for InlineCode.
 */
export const inlineCodeStyle = createDecoPlugin(() => {
  return createDecos('InlineCode', node => {
    const { from, to } = node;
    if (to - from < 2) {
      // Skip degenerate spans from partial parses
      return null;
    }

    // Tile the range with non-overlapping marks so the boundary class lands on the
    // background element itself, visible spaces only ever split the middle tile
    const base = 'cm-md-monospace cm-md-inlineCode';
    const ranges = [
      Decoration.mark({ class: `${base} cm-md-inlineCodeStart` }).range(from, from + 1),
      Decoration.mark({ class: `${base} cm-md-inlineCodeEnd` }).range(to - 1, to),
    ];

    if (from + 1 < to - 1) {
      ranges.push(Decoration.mark({ class: base }).range(from + 1, to - 1));
    }

    return ranges;
  });
});

/**
 * Always use monospace font for FencedCode and CodeBlock.
 */
export const codeBlockStyle = (() => {
  const nodeNames = ['FencedCode', 'CodeBlock'];
  return [
    createBlockPlugin(() => createBlockWrappers(nodeNames, 'cm-md-codeBlockWrapper', {
      'spellcheck': 'false',
      'autocorrect': 'off',
      'autocomplete': 'off',
      'autocapitalize': 'off',
    })),
    createDecoPlugin(() => createLineDeco(nodeNames, 'cm-md-monospace cm-md-codeBlock')),
  ];
})();

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
    if (container?.name !== 'FencedCode') {
      return null;
    }

    const boundary = container.lastChild;
    if (boundary?.name !== 'CodeMark') {
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
