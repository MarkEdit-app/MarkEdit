import { EditorView } from '@codemirror/view';
import { EditorColors, EditorTheme } from './types';
import { Config, WebFontFace, InvisiblesBehavior } from '../config';
import { editingState, styleSheets } from '../common/store';
import { refreshEditFocus } from '../modules/selection';
import { gutterExtensions } from './nodes/gutter';
import { invisiblesExtension } from './nodes/invisible';
import { lineIndicatorLayer } from './nodes/line';
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
    styleSheets.fontFace = createStyleSheet('.cm-content {}');
  }

  updateStyleSheet(styleSheets.fontFace, style => {
    style.fontWeight = fontFace.weight ?? '';
    style.fontStyle = fontFace.style ?? '';

    // If the desired font is ui-monospace, prefix it with the bundled SF Mono.
    //
    // The reason is that the system mono fonts don't work well with visible whitespaces,
    // some glyphs are slightly cropped.
    //
    // The bundled SF Mono is in woff2 format, which has better compatibility.
    const systemMono = 'SF Mono, ui-monospace';
    const preferredFont = fontFace.family === 'ui-monospace' ? systemMono : fontFace.family;

    const fontFamilies = [
      preferredFont,
      systemMono, 'monospace', 'Menlo',
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
      effects: window.dynamics.activeLine?.reconfigure(enabled ? lineIndicatorLayer : []),
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

    // The state is not initially correct without a focus refresh
    if (enabled) {
      setTimeout(refreshEditFocus, 5);
    }
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

  // Delay setting the transition to work around the issue mentioned in #436
  const foldGutter = document.querySelector('.cm-foldGutter') as HTMLElement | null;
  if (foldGutter !== null) {
    foldGutter.style.transition = '0.4s';
  }
}

function createStyleSheet(styleText: string, enabled = true) {
  const style = document.createElement('style');
  style.textContent = styleText;
  style.disabled = !enabled;

  document.head.appendChild(style);
  return style;
}
