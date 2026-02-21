import { createBlockWrappers, createLineDeco, createWidgetDeco } from '../matchers/lezer';
import { createBlockPlugin, createDecoPlugin } from '../helper';
import { PreviewWidget } from '../views';
import { cancelDefaultEvent, PreviewType, showPreview } from '../../modules/preview';

/**
 * Always use monospace font for Table.
 */
export const tableStyle = [
  createBlockPlugin(() => createBlockWrappers('Table', 'cm-md-tableWrapper')),
  createDecoPlugin(() => createLineDeco('Table', 'cm-md-monospace cm-md-table')),
];

/**
 * Enable [preview] button for GFM tables.
 */
export const previewTable = createDecoPlugin(() => {
  return createWidgetDeco('Table', node => {
    const header = node.node.getChild('TableHeader');
    if (header === null) {
      return null;
    }

    const state = window.editor.state;
    const code = state.sliceDoc(node.from, node.to);
    return new PreviewWidget(code, PreviewType.table, header.to);
  });
}, {
  click: showPreview,
  mousedown: cancelDefaultEvent,
});
