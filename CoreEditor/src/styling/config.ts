import { EditorView, highlightActiveLine } from '@codemirror/view';
import { EditorTheme } from './themes';
import { Config, InvisiblesBehavior } from '../config';
import { selectionState, styleSheets } from '../common/store';
import { gutterExtensions } from './nodes/gutter';
import { invisiblesExtension } from './nodes/invisible';
import { selectedLinesDecoration } from './nodes/selection';
import { calculateFontSize } from './nodes/heading';
import { shadowableTextColor, updateStyleSheet } from './helper';

/**
 * Style sheets that can be changed dynamically.
 *
 * Generally, we can either disable them or update css rules inside them.
 */
export default interface StyleSheets {
  accentColor?: HTMLStyleElement;
  fontFamily?: HTMLStyleElement;
  fontSize?: HTMLStyleElement;
  invisibles?: HTMLStyleElement;
  focusMode?: HTMLStyleElement;
  lineHeight?: HTMLStyleElement;
}

export function setUp(config: Config, accentColor: string) {
  setAccentColor(accentColor);
  setFontFamily(config.fontFamily);
  setFontSize(config.fontSize);
  setInvisiblesBehavior(config.invisiblesBehavior);
  setFocusMode(config.focusMode);
  setLineHeight(config.lineHeight);
}

export function setTheme(theme: EditorTheme) {
  const editor = window.editor as EditorView | null;

  // Editor may have not been initialized
  if (typeof editor?.dispatch === 'function') {
    editor.dispatch({
      effects: window.dynamics.theme.reconfigure(theme.extension),
    });
  }

  setAccentColor(theme.accentColor);
}

export function setAccentColor(accentColor: string) {
  if (styleSheets.accentColor === undefined) {
    const style = document.createElement('style');
    style.textContent = '.cm-md-header {}';

    styleSheets.accentColor = style;
    document.head.appendChild(style);
  }

  updateStyleSheet(styleSheets.accentColor, style => {
    const cssColor = shadowableTextColor(accentColor);
    Object.keys(cssColor).forEach(key => style.setProperty(key, cssColor[key] as string));
  });
}

export function setFontFamily(fontFamily: string) {
  if (styleSheets.fontFamily === undefined) {
    const style = document.createElement('style');
    style.textContent = '.cm-content * {}';

    styleSheets.fontFamily = style;
    document.head.appendChild(style);
  }

  updateStyleSheet(styleSheets.fontFamily, style => style.fontFamily = fontFamily);
}

export function setFontSize(fontSize: number) {
  if (styleSheets.fontSize === undefined) {
    const style = document.createElement('style');
    style.textContent = `
      .cm-editor:not(.cm-md-frontMatter *) {}
      .cm-md-heading1:not(.cm-md-frontMatter *) {}
      .cm-md-heading2:not(.cm-md-frontMatter *) {}
      .cm-md-heading3:not(.cm-md-frontMatter *) {}
    `;

    styleSheets.fontSize = style;
    document.head.appendChild(style);
  }

  updateStyleSheet(styleSheets.fontSize, (style, rule) => {
    // E.g., .cm-md-heading1 -> 1, .cm-editor -> 0
    const selector = rule.selectorText.split(':')[0];
    const headingLevel = parseInt(selector.slice(-1)) || 0;
    style.fontSize = `${calculateFontSize(fontSize, headingLevel)}px`;
  });
}

export function setShowLineNumbers(enabled: boolean) {
  const editor = window.editor as EditorView | null;
  if (typeof editor?.dispatch === 'function') {
    editor.dispatch({
      effects: window.dynamics.gutters?.reconfigure(enabled ? gutterExtensions : []),
    });
  }
}

export function setShowActiveLineIndicator(enabled: boolean) {
  const editor = window.editor as EditorView | null;
  if (typeof editor?.dispatch === 'function') {
    editor.dispatch({
      effects: window.dynamics.activeLine?.reconfigure(enabled ? highlightActiveLine() : []),
    });
  }
}

export function setInvisiblesBehavior(behavior: InvisiblesBehavior) {
  const editor = window.editor as EditorView | null;
  const hasSelection = selectionState.hasSelection;

  if (typeof editor?.dispatch === 'function') {
    editor.dispatch({
      effects: window.dynamics.invisibles?.reconfigure(invisiblesExtension(behavior, hasSelection)),
    });
  }

  if (styleSheets.invisibles === undefined) {
    const style = document.createElement('style');
    style.textContent = `
      .cm-visibleTab:not(.cm-selectedTextRange *) {
        background-color: #00000000;
      }

      .cm-visibleSpace:not(.cm-selectedTextRange *)::before {
        color: #00000000;
      }
    `;

    style.disabled = true;
    styleSheets.invisibles = style;
    document.head.appendChild(style);
  }

  styleSheets.invisibles.disabled = behavior !== InvisiblesBehavior.selection;
}

export function setFocusMode(enabled: boolean) {
  const editor = window.editor as EditorView | null;
  if (typeof editor?.dispatch === 'function') {
    editor.dispatch({
      effects: window.dynamics.selectedLines?.reconfigure(enabled ? selectedLinesDecoration : []),
    });
  }

  if (styleSheets.focusMode === undefined) {
    const style = document.createElement('style');
    style.textContent = `
      .cm-line:not(.cm-selectedLineRange), .cm-gutterElement:not(.cm-activeLineGutter) {
        filter: grayscale(1);
        opacity: 0.3;
      }
    `;

    style.disabled = true;
    styleSheets.focusMode = style;
    document.head.appendChild(style);
  }

  styleSheets.focusMode.disabled = !enabled;
}

export function setLineWrapping(enabled: boolean) {
  const editor = window.editor as EditorView | null;
  if (typeof editor?.dispatch === 'function') {
    editor.dispatch({
      effects: window.dynamics.lineWrapping?.reconfigure(enabled ? EditorView.lineWrapping : []),
    });
  }
}

export function setLineHeight(lineHeight: number) {
  if (styleSheets.lineHeight === undefined) {
    const style = document.createElement('style');
    style.textContent = '.cm-line {}';

    styleSheets.lineHeight = style;
    document.head.appendChild(style);
  }

  updateStyleSheet(styleSheets.lineHeight, style => style.lineHeight = `${lineHeight * 100}%`);
}
