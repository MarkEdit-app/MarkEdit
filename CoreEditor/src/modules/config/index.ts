import { EditorView } from '@codemirror/view';
import { EditorState } from '@codemirror/state';
import { indentUnit } from '@codemirror/language';
import { WebFontFace, InvisiblesBehavior } from '../../config';
import { TabKeyBehavior } from '../indentation';
import { adjustGutterPositions } from '../lines';
import { refreshEditFocus, scrollToSelection } from '../selection';
import { editingState } from '../../common/store';
import { tryGetEditor, afterDomUpdate } from '../../common/utils';
import { notifyBackgroundColor } from '../../styling/helper';
import { loadTheme } from '../../styling/themes';
import { notifyEditorConfigChange } from '../../api/methods';

import * as styling from '../../styling/config';
import * as completion from '../completion';

export function setTheme(name: string) {
  window.config.theme = name;
  styling.setTheme(loadTheme(name));
  afterDomUpdate(notifyBackgroundColor);
  notifyEditorConfigChange('theme', name);
}

export function setFontFace(fontFace: WebFontFace) {
  styling.setFontFace(fontFace);
  window.config.fontFace = fontFace;

  const editor = tryGetEditor();
  if (editor !== null) {
    editor.requestMeasure();
    refreshEditFocus();
  }

  recalculateTextMetrics();
  notifyEditorConfigChange('fontFace', fontFace);
}

export function setFontSize(fontSize: number) {
  styling.setFontSize(fontSize);
  window.config.fontSize = fontSize;

  const editor = tryGetEditor();
  if (editor !== null) {
    editor.requestMeasure();
    refreshEditFocus();
  }

  recalculateTextMetrics();
  notifyEditorConfigChange('fontSize', fontSize);
}

export function setShowLineNumbers(enabled: boolean) {
  window.config.showLineNumbers = enabled;
  styling.setShowLineNumbers(enabled);

  // Redraw active line indicator to fill the editor width
  if (!enabled && window.config.showActiveLineIndicator) {
    refreshEditFocus();
  }

  adjustGutterPositions();
  notifyEditorConfigChange('showLineNumbers', enabled);
}

export function setShowActiveLineIndicator(enabled: boolean) {
  window.config.showActiveLineIndicator = enabled;
  styling.setShowActiveLineIndicator(enabled && !editingState.hasSelection);
  notifyEditorConfigChange('showActiveLineIndicator', enabled);
}

export function setInvisiblesBehavior(behavior: InvisiblesBehavior, updateSelection = false) {
  const changed = window.config.invisiblesBehavior !== behavior;
  window.config.invisiblesBehavior = behavior;
  styling.setInvisiblesBehavior(behavior);

  // Force a selection update to ensure invisible for selections
  if (updateSelection && behavior === InvisiblesBehavior.selection) {
    const selection = window.editor.state.selection;
    window.editor.dispatch({ selection });
  }

  if (changed) {
    notifyEditorConfigChange('invisiblesBehavior', behavior);
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

  notifyEditorConfigChange('readOnlyMode', enabled);
}

export function setTypewriterMode(enabled: boolean) {
  window.config.typewriterMode = enabled;
  styling.setTypewriterMode(enabled);

  scrollToSelection(enabled ? 'center' : 'nearest');
  notifyEditorConfigChange('typewriterMode', enabled);
}

export function setFocusMode(enabled: boolean) {
  window.config.focusMode = enabled;
  styling.setFocusMode(enabled);
  notifyEditorConfigChange('focusMode', enabled);
}

export function setLineWrapping(enabled: boolean) {
  window.config.lineWrapping = enabled;
  styling.setLineWrapping(enabled);
  notifyEditorConfigChange('lineWrapping', enabled);
}

export function setLineHeight(lineHeight: number) {
  window.config.lineHeight = lineHeight;
  styling.setLineHeight(lineHeight);

  // Redraw active line indicator to fill the line height
  if (window.config.showActiveLineIndicator) {
    refreshEditFocus();
  }

  notifyEditorConfigChange('lineHeight', lineHeight);
}

export function setDefaultLineBreak(lineBreak?: string) {
  window.config.defaultLineBreak = lineBreak;
  notifyEditorConfigChange('defaultLineBreak', lineBreak);
}

export function setIndentUnit(unit: string) {
  window.config.indentUnit = unit;
  tryGetEditor()?.dispatch({
    effects: window.dynamics.indentUnit?.reconfigure(indentUnit.of(unit)),
  });

  notifyEditorConfigChange('indentUnit', unit);
}

export function setTabKeyBehavior(behavior: TabKeyBehavior) {
  window.config.tabKeyBehavior = behavior as CodeGen_Int;
  notifyEditorConfigChange('tabKeyBehavior', behavior as CodeGen_Int);
}

export function setSuggestWhileTyping(enabled: boolean) {
  window.config.suggestWhileTyping = enabled;
  completion.invalidateCache();
  notifyEditorConfigChange('suggestWhileTyping', enabled);
}

export function setSmartQuotesEnabled(enabled: boolean) {
  window.config.smartQuotesEnabled = enabled;
  notifyEditorConfigChange('smartQuotesEnabled', enabled);
}

export function recalculateTextMetrics() {
  adjustGutterPositions();

  const span = document.createElement('span');
  span.style.font = `${window.config.fontSize}px ${window.config.fontFace.family}`;
  span.style.lineHeight = '1.2';
  span.style.position = 'absolute';
  span.style.visibility = 'hidden';
  span.textContent = '#markedit-v1.0';
  document.body.appendChild(span);

  const metrics = span.getBoundingClientRect();
  const rowHeight = metrics.height + 8; // padding = 4px
  const totalHeight = `${rowHeight * 6}px`;

  document.documentElement.style.setProperty('--tooltip-completion-max-height', totalHeight);
  document.body.removeChild(span);
}

