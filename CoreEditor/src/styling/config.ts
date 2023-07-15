import { EditorView, highlightActiveLine } from '@codemirror/view';
import { EditorTheme } from './themes';
import { Config, InvisiblesBehavior } from '../config';
import { editingState, styleSheets } from '../common/store';
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
  gutterHoverDelay?: HTMLStyleElement;
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
    styleSheets.accentColor = createStyleSheet('.cm-md-header {}');
  }

  updateStyleSheet(styleSheets.accentColor, style => {
    const cssColor = shadowableTextColor(accentColor);
    Object.keys(cssColor).forEach(key => style.setProperty(key, cssColor[key] as string));
  });
}

export function setFontFamily(fontFamily: string) {
  if (styleSheets.fontFamily === undefined) {
    styleSheets.fontFamily = createStyleSheet('.cm-content * {}');
  }

  updateStyleSheet(styleSheets.fontFamily, style => style.fontFamily = fontFamily);
}

export function setFontSize(fontSize: number) {
  if (styleSheets.fontSize === undefined) {
    styleSheets.fontSize = createStyleSheet(`
      .cm-editor:not(.cm-md-frontMatter *) {}
      .cm-md-heading1:not(.cm-md-frontMatter *) {}
      .cm-md-heading2:not(.cm-md-frontMatter *) {}
      .cm-md-heading3:not(.cm-md-frontMatter *) {}
    `);
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
  const hasSelection = editingState.hasSelection;

  if (typeof editor?.dispatch === 'function') {
    editor.dispatch({
      effects: window.dynamics.invisibles?.reconfigure(invisiblesExtension(behavior, hasSelection)),
    });
  }

  if (styleSheets.invisibles === undefined) {
    styleSheets.invisibles = createStyleSheet(`
      .cm-visibleTab:not(.cm-selectedTextRange *) {
        background-color: #00000000;
      }

      .cm-visibleSpace:not(.cm-selectedTextRange *)::before {
        color: #00000000;
      }
    `, false);
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
    styleSheets.focusMode = createStyleSheet(`
      .cm-line:not(.cm-selectedLineRange), .cm-gutterElement:not(.cm-activeLineGutter) {
        opacity: 0.25;
      }
    `, false);
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
    styleSheets.lineHeight = createStyleSheet('.cm-line {}');
  }

  updateStyleSheet(styleSheets.lineHeight, style => style.lineHeight = `${lineHeight * 100}%`);
}

export function setGutterHoverDelay(enabled: boolean) {
  if (styleSheets.gutterHoverDelay === undefined) {
    // To work around :hover is not reset when mouse is released outside the window
    styleSheets.gutterHoverDelay = createStyleSheet(`
      .cm-gutters:hover .cm-foldGutter:not(:hover), .cm-foldGutter:hover {
        transition-delay: 3000000s;
      }
    `, false);
  }

  styleSheets.gutterHoverDelay.disabled = !enabled;
}

function createStyleSheet(styleText: string, enabled = true) {
  const style = document.createElement('style');
  style.textContent = styleText;
  style.disabled = !enabled;

  document.head.appendChild(style);
  return style;
}
