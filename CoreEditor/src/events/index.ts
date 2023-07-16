import isMetaKey from './isMetaKey';
import { editingState } from '../common/store';

import * as completion from '../modules/completion';
import * as grammarly from '../modules/grammarly';
import * as selection from '../modules/selection';
import * as tokenizer from '../modules/tokenizer';
import * as link from '../styling/nodes/link';

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
  });

  document.addEventListener('keyup', () => {
    link.stopClickable();
  });

  document.addEventListener('mousedown', event => {
    storage.isMouseDown = true;
    link.handleMouseDown(event);
  }, true);

  document.addEventListener('mouseup', event => {
    storage.isMouseDown = false;
    link.handleMouseUp(event);
  }, true);

  document.addEventListener('compositionstart', () => {
    editingState.compositionEnded = false;
  });

  document.addEventListener('compositionend', () => {
    editingState.compositionEnded = true;
  });

  document.addEventListener('scroll', () => {
    // Dismiss the completion panel whenever the document scrolls,
    // it happens usually when the page is scaled, i.e., it's not the actual size.
    if (completion.isPanelVisible()) {
      window.nativeModules.completion.cancelCompletion();
    }
  });

  observeEventsForTokenization();
  observeEventsForCompletion();
}

export function isMouseDown() {
  return storage.isMouseDown;
}

function observeEventsForTokenization() {
  document.addEventListener('dblclick', event => {
    tokenizer.handleDoubleClick(event);
  });

  document.addEventListener('keydown', event => {
    tokenizer.handleKeyDown(event);
  }, true);
}

function observeEventsForCompletion() {
  document.addEventListener('keydown', event => {
    if (!completion.isPanelVisible()) {
      return;
    }

    const skipDefaultBehavior = () => {
      event.preventDefault();
      event.stopPropagation();
    };

    if (event.key === 'ArrowUp' || (event.key === 'p' && event.ctrlKey)) {
      if (event.metaKey) {
        window.nativeModules.completion.selectTop();
      } else {
        window.nativeModules.completion.selectPrevious();
      }
      return skipDefaultBehavior();
    }

    if (event.key === 'ArrowDown' || (event.key === 'n' && event.ctrlKey)) {
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

    // We don't need to call skipDefaultBehavior for this one
    if (event.key === 'Backspace' || (event.key === 'z' && event.metaKey)) {
      return window.nativeModules.completion.cancelCompletion();
    }
  }, true);
}

const storage: { isMouseDown: boolean } = { isMouseDown: false };
