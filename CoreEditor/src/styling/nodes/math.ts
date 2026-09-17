import { createWidgetDeco } from '../matchers/lezer';
import { createDecoPlugin } from '../helper';
import { PreviewWidget } from '../views';
import { cancelDefaultEvent, PreviewType, showPreview } from '../../modules/preview';
import { blockMathContentTagName } from '../../modules/math';

/**
 * Enable [preview] button for https://katex.org/.
 */
export const previewMath = createDecoPlugin(() => {
  return createWidgetDeco('BlockMath', node => {
    const state = window.editor.state;
    const code = node.node.getChildren(blockMathContentTagName)
      .map(content => state.sliceDoc(content.from, content.to)).join('');
    if (code.trim().length === 0) {
      return null;
    }

    return new PreviewWidget(code, PreviewType.katex, node.from + 2);
  });
}, {
  click: showPreview,
  mousedown: cancelDefaultEvent,
});
