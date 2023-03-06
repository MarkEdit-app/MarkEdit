import { EditorView } from '@codemirror/view';
import { indentUnit } from '@codemirror/language';
import { InvisiblesBehavior } from '../../config';
import { TabKeyBehavior } from '../indentation';
import { scrollToSelection } from '../selection';
import { editingState } from '../../common/store';
import { loadTheme } from '../../styling/themes';

import * as styling from '../../styling/config';
import * as completion from '../completion';

export function setTheme(name: string) {
  window.config.theme = name;
  styling.setTheme(loadTheme(name));
}

export function setFontFamily(fontFamily: string) {
  window.config.fontFamily = fontFamily;
  styling.setFontFamily(fontFamily);
}

export function setFontSize(fontSize: number) {
  window.config.fontSize = fontSize;
  styling.setFontSize(fontSize);
}

export function setShowLineNumbers(enabled: boolean) {
  window.config.showLineNumbers = enabled;
  styling.setShowLineNumbers(enabled);
}

export function setShowActiveLineIndicator(enabled: boolean) {
  window.config.showActiveLineIndicator = enabled;
  styling.setShowActiveLineIndicator(enabled && !editingState.hasSelection);
}

export function setInvisiblesBehavior(behavior: InvisiblesBehavior) {
  window.config.invisiblesBehavior = behavior;
  styling.setInvisiblesBehavior(behavior);
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
