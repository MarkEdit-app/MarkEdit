import isMetaKey from './isMetaKey';
import { editingState } from '../common/store';

import * as completion from '../modules/completion';
import * as selection from '../modules/selection';
import * as tokenizer from '../modules/tokenizer';
import * as invisible from '../styling/nodes/invisible';
import * as link from '../styling/nodes/link';

export function startObserving() {
  document.addEventListener('click', event => {
    selection.selectWholeLineIfNeeded(event);
  });

  document.addEventListener('keydown', event => {
    if (event.key === ' ') {
      invisible.renderWhitespaceBeforeCaret();
    }

    if (isMetaKey(event)) {
      storage.isMetaKeyDown = true;
      link.startClickable();
    }
  });

  document.addEventListener('keyup', event => {
    if (isMetaKey(event)) {
      storage.isMetaKeyDown = false;
      link.stopClickable();
    }
  });

  document.addEventListener('mousedown', event => {
    storage.isMouseDown = true;
    link.handleMouseDown(event);
  }, true);

  document.addEventListener('mouseup', event => {
    storage.isMouseDown = false;
    link.handleMouseUp(event);
  }, true);

  // Handle edge cases where 'keyup' is not fired
  document.addEventListener('contextmenu', resetKeyStates);

  document.addEventListener('compositionstart', () => {
    editingState.compositionEnded = false;
    storage.selectedTextBeforeCompose = editingState.hasSelection;
  });

  document.addEventListener('compositionend', () => {
    editingState.compositionEnded = true;

    // [macOS 15] 'compositionend' is received before the editor is initialized
    if (typeof window.editor !== 'object') {
      return;
    }

    // When composition has just finished, the selection is considered empty
    if (storage.selectedTextBeforeCompose) {
      selection.updateActiveLine(false);
      storage.selectedTextBeforeCompose = false;
    }

    // Input methods like Pinyin may not trigger 'inputHandler' on 'compositionend',
    // manually update the selection with an additional call.
    window.nativeModules.core.notifyCompositionEnded({
      selectedLineColumn: selection.selectedLineColumn(),
    });
  });

  // It happens usually when the page is scaled, i.e., it's not the actual size
  document.addEventListener('scroll', () => {
    clearTimeout(storage.scrollTimer);
    storage.scrollTimer = setTimeout(() => window.nativeModules.core.notifyContentOffsetDidChange(), 100);
  });

  observeEventsForTokenization();
  observeEventsForCompletion();
}

export function isMouseDown() {
  return storage.isMouseDown;
}

export function isMetaKeyDown() {
  return storage.isMetaKeyDown;
}

export function resetKeyStates() {
  storage.isMouseDown = false;
  storage.isMetaKeyDown = false;
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

const storage: {
  scrollTimer: ReturnType<typeof setTimeout> | undefined;
  isMouseDown: boolean;
  isMetaKeyDown: boolean;
  selectedTextBeforeCompose: boolean;
} = {
  scrollTimer: undefined,
  isMouseDown: false,
  isMetaKeyDown: false,
  selectedTextBeforeCompose: false,
};
