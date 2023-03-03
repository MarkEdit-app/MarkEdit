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

  overrideNavigationKeysForCompletion();
}

function overrideNavigationKeysForCompletion() {
  document.addEventListener('keydown', event => {
    if (!isPanelVisible()) {
      return;
    }

    const skipDefaultBehavior = () => {
      event.preventDefault();
      event.stopPropagation();
    };

    if (event.key === 'ArrowUp') {
      window.nativeModules.completion.selectPrevious();
      return skipDefaultBehavior();
    }

    if (event.key === 'ArrowDown') {
      window.nativeModules.completion.selectNext();
      return skipDefaultBehavior();
    }

    if (event.key === 'Enter' || event.key === 'Tab') {
      window.nativeModules.completion.commitCompletion();
      return skipDefaultBehavior();
    }

    if (event.key === 'Backspace') {
      window.nativeModules.completion.cancelCompletion();
      return skipDefaultBehavior();
    }
  }, true);
}
