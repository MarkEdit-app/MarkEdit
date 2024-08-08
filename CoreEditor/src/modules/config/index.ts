import { EditorView } from '@codemirror/view';
import { EditorState } from '@codemirror/state';
import { indentUnit } from '@codemirror/language';
import { closeBrackets } from '@codemirror/autocomplete';
import { WebFontFace, InvisiblesBehavior } from '../../config';
import { TabKeyBehavior } from '../indentation';
import { refreshEditFocus, scrollToSelection } from '../selection';
import { editingState } from '../../common/store';
import { notifyBackgroundColor } from '../../common/utils';
import { loadTheme } from '../../styling/themes';

import * as styling from '../../styling/config';
import * as completion from '../completion';

export function setTheme(name: string) {
  window.config.theme = name;
  styling.setTheme(loadTheme(name));
  setTimeout(notifyBackgroundColor, 100);
}

export function setFontFace(fontFace: WebFontFace) {
  styling.setFontFace(fontFace);
  window.config.fontFace = fontFace;
  window.editor.requestMeasure();
}

export function setFontSize(fontSize: number) {
  styling.setFontSize(fontSize);
  window.config.fontSize = fontSize;
  window.editor.requestMeasure();
}

export function setShowLineNumbers(enabled: boolean) {
  window.config.showLineNumbers = enabled;
  styling.setShowLineNumbers(enabled);
}

export function setShowActiveLineIndicator(enabled: boolean) {
  window.config.showActiveLineIndicator = enabled;
  styling.setShowActiveLineIndicator(enabled && !editingState.hasSelection);
}

export function setInvisiblesBehavior(behavior: InvisiblesBehavior, updateSelection = false) {
  window.config.invisiblesBehavior = behavior;
  styling.setInvisiblesBehavior(behavior);

  // Force a selection update to ensure invisible for selections
  if (updateSelection && behavior === InvisiblesBehavior.selection) {
    const selection = window.editor.state.selection;
    window.editor.dispatch({ selection });
  }
}

export function setReadOnlyMode(enabled: boolean) {
  window.editor.dispatch({
    effects: window.dynamics.readOnly?.reconfigure(enabled ? [EditorView.editable.of(false), EditorState.readOnly.of(true)] : []),
  });

  window.config.readOnlyMode = enabled;
  refreshEditFocus();

  if (enabled) {
    window.editor.contentDOM.blur();
  } else {
    window.editor.contentDOM.focus();
  }
}

export function setTypewriterMode(enabled: boolean) {
  window.config.typewriterMode = enabled;

  if (enabled) {
    scrollToSelection('center');
  }
}

export function setFocusMode(enabled: boolean) {
  window.config.focusMode = enabled;
  styling.setFocusMode(enabled);
}

export function setLineWrapping(enabled: boolean) {
  window.config.lineWrapping = enabled;
  styling.setLineWrapping(enabled);
}

export function setLineHeight(lineHeight: number) {
  window.config.lineHeight = lineHeight;
  styling.setLineHeight(lineHeight);
}

export function setIndentParagraphs(enabled: boolean) {
  window.config.indentParagraphs = enabled;
  styling.setIndentParagraphs(enabled);
}

export function setDefaultLineBreak(lineBreak?: string) {
  window.config.defaultLineBreak = lineBreak;
}

export function setIndentUnit(unit: string) {
  window.config.indentUnit = unit;

  const editor = window.editor as EditorView | null;
  if (typeof editor?.dispatch === 'function') {
    editor.dispatch({
      effects: window.dynamics.indentUnit?.reconfigure(indentUnit.of(unit)),
    });
  }
}

export function setTabKeyBehavior(behavior: TabKeyBehavior) {
  window.config.tabKeyBehavior = behavior as CodeGen_Int;
}

export function setSuggestWhileTyping(enabled: boolean) {
  window.config.suggestWhileTyping = enabled;
  completion.invalidateCache();
}

export function setAutoCharacterPairs(enabled: boolean) {
  window.config.autoCharacterPairs = enabled;

  const editor = window.editor as EditorView | null;
  if (typeof editor?.dispatch === 'function') {
    editor.dispatch({
      effects: window.dynamics.closeBrackets?.reconfigure(enabled ? closeBrackets() : []),
    });
  }
}
