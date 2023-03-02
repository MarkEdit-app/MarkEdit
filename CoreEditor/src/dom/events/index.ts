import isMetaKey from './isMetaKey';
import { editingState } from '../../common/store';

import * as grammarly from '../../modules/grammarly';
import * as selection from '../../modules/selection';
import * as tokenizer from '../../modules/tokenizer';
import * as link from '../../styling/nodes/link';

export function startObserving() {
  document.addEventListener('click', event => {
    grammarly.centerActiveDialog();
    selection.selectWholeLineIfNeeded(event);
  });

  document.addEventListener('dblclick', event => {
    tokenizer.handleDoubleClick(event);
  });

  document.addEventListener('keydown', event => {
    if (isMetaKey(event)) {
      link.startClickable();
    } else {
      link.stopClickable();
    }
  });

  document.addEventListener('keyup', () => {
    link.stopClickable();
  });

  document.addEventListener('mousedown', event => {
    link.handleMouseDown(event);
  }, true);

  document.addEventListener('mouseup', event => {
    link.handleMouseUp(event);
  }, true);

  document.addEventListener('compositionstart', () => {
    editingState.compositionEnded = false;
  });

  document.addEventListener('compositionend', () => {
    editingState.compositionEnded = true;
  });
}
