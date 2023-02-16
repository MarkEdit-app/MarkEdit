import { scrollCaretToVisible, scrollToSelection } from '../../modules/selection';
import isMetaKey from './isMetaKey';

import * as grammarly from '../../modules/grammarly';
import * as selection from '../../modules/selection';
import * as link from '../../styling/nodes/link';

export function startObserving() {
  document.addEventListener('click', event => {
    grammarly.centerActiveDialog();
    selection.selectWholeLineIfNeeded(event);
  });

  document.addEventListener('keydown', event => {
    if (isMetaKey(event)) {
      link.startClickable();
    } else {
      link.stopClickable();
    }

    // Make sure the main selection is always centered for typewriter mode
    if (window.config.typewriterMode) {
      scrollToSelection('center');
    } else {
      // We need this because we have different line height for headings,
      // CodeMirror doesn't by default fix the offset issue.
      scrollCaretToVisible();
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
}
