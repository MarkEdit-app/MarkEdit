import { EditorView } from '@codemirror/view';
import { indentUnit } from '@codemirror/language';
import { TabKeyBehavior } from '../indentation';
import { scrollToSelection } from '../selection';
import { selectionState } from '../../common/store';
import { loadTheme } from '../../styling/themes';
import * as styling from '../../styling/config';

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
  styling.setShowActiveLineIndicator(enabled && !selectionState.hasSelection);
}

export function setShowInvisibles(enabled: boolean) {
  window.config.showInvisibles = enabled;
  styling.setShowInvisibles(enabled);
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
