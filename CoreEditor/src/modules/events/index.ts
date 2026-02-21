import { isMetaKey } from '../../common/utils';
import { globalState, editingState } from '../../common/store';

import * as completion from '../../modules/completion';
import * as selection from '../../modules/selection';
import * as tokenizer from '../../modules/tokenizer';
import * as invisible from '../../styling/nodes/invisible';
import * as link from '../../styling/nodes/link';
import * as task from '../../styling/nodes/task';

export function startObserving() {
  document.addEventListener('mousedown', event => {
    selection.selectWholeLineIfNeeded(event);
    storage.mouseDownTime = Date.now();
  });

  document.addEventListener('keydown', event => {
    if (event.key === ' ') {
      invisible.renderWhitespaceBeforeCaret();
    }

    if (isMetaKey(event)) {
      storage.isMetaKeyDown = true;
      link.startClickable();
      task.startClickable();
    }

    storage.keyPressTime = Date.now();
  });

  document.addEventListener('keyup', event => {
    if (isMetaKey(event)) {
      storage.isMetaKeyDown = false;
      link.stopClickable();
      task.stopClickable();
    }
  });

  document.addEventListener('mousedown', event => {
    storage.isMouseDown = true;
    link.handleMouseDown(event);

    if (isMetaKeyDown()) {
      task.handleMouseDown(event);
    }
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
  if ('onscrollend' in window) { // [macOS] 26.2
    document.addEventListener('scrollend', () => {
      window.nativeModules.core.notifyContentOffsetDidChange();
    });
  } else {
    document.addEventListener('scroll', () => {
      clearTimeout(storage.scrollTimer);
      storage.scrollTimer = setTimeout(() => window.nativeModules.core.notifyContentOffsetDidChange(), 100);
    });
  }

  // Captures the time a context menu is opened, primarily to prevent automatic line break selection
  document.addEventListener('contextmenu', () => {
    globalState.contextMenuOpenTime = Date.now();
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

export function hasRecentKeyPress() {
  return Date.now() - storage.keyPressTime < 150;
}

export function resetKeyStates() {
  storage.isMouseDown = false;
  storage.isMetaKeyDown = false;

  link.stopClickable();
  task.stopClickable();
}

function observeEventsForTokenization() {
  document.addEventListener('dblclick', event => {
    if (Date.now() - storage.mouseDownTime > 500) {
      // Mouse up after a significant delay, text selection might have changed
      return;
    }

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

    if (['Enter', 'Tab', ',', '.'].includes(event.key)) {
      const insert = event.key.length > 1 ? undefined : `${event.key} `;
      window.nativeModules.completion.commitCompletion({ insert });
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
  mouseDownTime: number;
  keyPressTime: number;
  selectedTextBeforeCompose: boolean;
} = {
  scrollTimer: undefined,
  isMouseDown: false,
  isMetaKeyDown: false,
  mouseDownTime: 0,
  keyPressTime: 0,
  selectedTextBeforeCompose: false,
};
