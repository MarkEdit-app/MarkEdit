import isMetaKey from './isMetaKey';
import { editingState } from '../../common/store';
import { isPanelVisible } from '../../modules/completion';

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

  overrideEventsForCompletion();
}

function overrideEventsForCompletion() {
  document.addEventListener('keydown', event => {
    if (!isPanelVisible()) {
      return;
    }

    const skipDefaultBehavior = () => {
      event.preventDefault();
      event.stopPropagation();
    };

    if (event.key === 'ArrowUp') {
      if (event.metaKey) {
        window.nativeModules.completion.selectTop();
      } else {
        window.nativeModules.completion.selectPrevious();
      }
      return skipDefaultBehavior();
    }

    if (event.key === 'ArrowDown') {
      if (event.metaKey) {
        window.nativeModules.completion.selectBottom();
      } else {
        window.nativeModules.completion.selectNext();
      }
      return skipDefaultBehavior();
    }

    if (event.key === 'Enter' || event.key === 'Tab') {
      window.nativeModules.completion.commitCompletion();
      return skipDefaultBehavior();
    }

    if (event.key === 'Backspace' || (event.key === 'z' && event.metaKey)) {
      return window.nativeModules.completion.cancelCompletion();
    }
  }, true);
}
