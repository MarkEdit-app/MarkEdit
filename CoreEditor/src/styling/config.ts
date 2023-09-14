import { EditorView, highlightActiveLine } from '@codemirror/view';
import { EditorColors, EditorTheme } from './types';
import { Config, WebFontFace, InvisiblesBehavior } from '../config';
import { editingState, styleSheets } from '../common/store';
import { gutterExtensions } from './nodes/gutter';
import { invisiblesExtension } from './nodes/invisible';
import { selectedLinesDecoration } from './nodes/selection';
import { calculateFontSize } from './nodes/heading';
import { shadowableTextColor, updateStyleSheet } from './helper';
import { isMouseDown } from '../events';

/**
 * Style sheets that can be changed dynamically.
 *
 * Generally, we can either disable them or update css rules inside them.
 */
export default interface StyleSheets {
  accentColor?: HTMLStyleElement;
  fontFace?: HTMLStyleElement;
  fontSize?: HTMLStyleElement;
  invisibles?: HTMLStyleElement;
  focusMode?: HTMLStyleElement;
  lineHeight?: HTMLStyleElement;
}

export function setUp(config: Config, colors: EditorColors) {
  setEditorColors(colors);
  setFontFace(config.fontFace);
  setFontSize(config.fontSize);
  setInvisiblesBehavior(config.invisiblesBehavior);
  setFocusMode(config.focusMode);
  setLineHeight(config.lineHeight);

  if (config.showLineNumbers) {
    // Delay because when the window is resizing, the mouse can enter and leave gutters rapidly
    setTimeout(enableGutterHoverEffects, 500);
  }
}

export function setTheme(theme: EditorTheme) {
  const editor = window.editor as EditorView | null;

  // Editor may have not been initialized
  if (typeof editor?.dispatch === 'function') {
    editor.dispatch({
      effects: window.dynamics.theme.reconfigure(theme.extension),
    });
  }

  setEditorColors(theme.colors);
}

export function setEditorColors(colors: EditorColors) {
  if (styleSheets.accentColor === undefined) {
    styleSheets.accentColor = createStyleSheet('.cm-md-header {}');
  }

  updateStyleSheet(styleSheets.accentColor, style => {
    const cssColor = shadowableTextColor(colors.accent);
    Object.keys(cssColor).forEach(key => style.setProperty(key, cssColor[key] as string));
  });

  window.colors = colors;
}

export function setFontFace(fontFace: WebFontFace) {
  if (styleSheets.fontFace === undefined) {
    styleSheets.fontFace = createStyleSheet('.cm-content * {}');
  }

  updateStyleSheet(styleSheets.fontFace, style => {
    style.fontWeight = fontFace.weight ?? 'normal';
    style.fontStyle = fontFace.style ?? 'normal';

    const fontFamilies = [
      fontFace.family,
      'ui-monospace', 'monospace', 'Menlo',
      'system-ui', 'Helvetica', 'Arial', 'sans-serif',
    ];

    // Set is ordered, it can safely dedupe items without messing up the order
    style.fontFamily = [...new Set(fontFamilies)].join(', ');
  });
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

  if (enabled) {
    enableGutterHoverEffects();
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
        background-color: #0000;
      }

      .cm-visibleSpace:not(.cm-selectedTextRange *)::before {
        color: #0000;
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

export function setGutterHovered(hovered: boolean) {
  const className = 'cm-gutterHover';
  const gutterDOM = document.querySelector('.cm-foldGutter') as HTMLElement | null;

  if (hovered) {
    gutterDOM?.classList.add(className);
  } else {
    gutterDOM?.classList.remove(className);
  }
}

function enableGutterHoverEffects() {
  const gutterDOM = document.querySelector('.cm-gutters') as HTMLElement | null;
  if (gutterDOM === null) {
    return;
  }

  // Intead of using the :hover pseudo class,
  // which is not reliable on WebKit when releasing the mouse outside the window,
  // we handle hover state manually and expose methods to native.
  gutterDOM.addEventListener('mouseleave', () => setGutterHovered(false));
  gutterDOM.addEventListener('mouseenter', () => {
    if (!isMouseDown()) {
      setGutterHovered(true);
    }
  });
}

function createStyleSheet(styleText: string, enabled = true) {
  const style = document.createElement('style');
  style.textContent = styleText;
  style.disabled = !enabled;

  document.head.appendChild(style);
  return style;
}
