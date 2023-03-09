import { createMarkDeco, createWidgetDeco } from '../matchers/lexer';
import { createDecoPlugin } from '../helper';
import { PreviewWidget } from '../../views';
import { PreviewType, showPreview } from '../../modules/preview';

/**
 * Always use monospace font for Table.
 */
export const tableStyle = createDecoPlugin(() => {
  return createMarkDeco('Table', 'cm-md-monospace cm-md-table');
});

/**
 * Enable [preview] button for GFM tables.
 */
export const previewTable = createDecoPlugin(() => {
  return createWidgetDeco('Table', node => {
    const header = node.node.firstChild?.node;
    if (header?.name !== 'TableHeader') {
      return null;
    }

    const state = window.editor.state;
    const code = state.doc.sliceString(node.from, node.to);
    return new PreviewWidget(code, PreviewType.table, header.to);
  });
}, { mouseup: showPreview });
