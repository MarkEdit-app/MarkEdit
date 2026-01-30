import { EditorView } from '@codemirror/view';
import { EditorColors, EditorTheme } from './types';
import { Config, WebFontFace, InvisiblesBehavior } from '../config';
import { globalState, editingState, styleSheets } from '../common/store';
import { adjustGutterPositions } from '../modules/lines';
import { refreshEditFocus } from '../modules/selection';
import { gutterExtensions } from './nodes/gutter';
import { invisiblesExtension } from './nodes/invisible';
import { lineIndicatorLayer } from './nodes/line';
import { selectedLinesDecoration } from './nodes/selection';
import { calculateFontSize } from './nodes/heading';
import { shadowableTextColor, updateStyleSheet } from './helper';
import { isMouseDown } from '../modules/events';
import { afterDomUpdate } from '../common/utils';

/**
 * Style sheets that can be changed dynamically.
 *
 * Generally, we can either disable them or update css rules inside them.
 */
export default interface StyleSheets {
  accentColor?: HTMLStyleElement;
  fontFace?: HTMLStyleElement;
  fontSize?: HTMLStyleElement;
  typewriterMode?: HTMLStyleElement;
  focusMode?: HTMLStyleElement;
  lineHeight?: HTMLStyleElement;
  taskMarker?: HTMLStyleElement;
}

export function setUp(config: Config, colors: EditorColors) {
  setEditorColors(colors);
  setFontFace(config.fontFace);
  setFontSize(config.fontSize);
  setInvisiblesBehavior(config.invisiblesBehavior);
  setTypewriterMode(config.typewriterMode);
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
    styleSheets.accentColor = createStyleSheet('.cm-md-header:not(.cm-md-quote) {}');
  }

  updateStyleSheet(styleSheets.accentColor, style => {
    const cssColor = shadowableTextColor(colors.accent);
    Object.keys(cssColor).forEach(key => style.setProperty(key, cssColor[key] as string));
  });

  globalState.colors = colors;
}

export function setFontFace(fontFace: WebFontFace) {
  if (styleSheets.fontFace === undefined) {
    styleSheets.fontFace = createStyleSheet('.cm-content, .cm-tooltip-autocomplete * {}');
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
    const h = (level: number): string => {
      const cls = `.cm-md-heading${level}`;
      return `${cls}, *:has(> ${cls}) {}`;
    };

    styleSheets.fontSize = createStyleSheet(`
      .cm-editor {}
      .cm-foldPlaceholder {}
      ${[h(1), h(2), h(3), h(4), h(5), h(6)].join('\n')}
    `);
  }

  updateStyleSheet(styleSheets.fontSize, (style, rule) => {
    // Smaller font size for fold placeholder (...)
    if (rule.selectorText === '.cm-foldPlaceholder') {
      style.fontSize = `${fontSize - 4}px`;
      return;
    }

    // E.g., .cm-md-heading1 -> 1, .cm-editor -> 0
    const match = rule.selectorText.match(/\d+/);
    const headingLevel = parseInt(match === null ? '0' : match[0]);
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

export function setTypewriterMode(enabled: boolean) {
  if (styleSheets.typewriterMode === undefined) {
    styleSheets.typewriterMode = createStyleSheet(`
      .cm-content {
        padding-top: 50vh !important;
      }
    `, false);
  }

  styleSheets.typewriterMode.disabled = !enabled;
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
      afterDomUpdate(refreshEditFocus);
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
    styleSheets.lineHeight = createStyleSheet('.cm-line, .cm-gutterElement {}');
  }

  // Prefer numbers (like 1.5) over percentages (like 150%), see https://developer.mozilla.org/en-US/docs/Web/CSS/line-height#number
  updateStyleSheet(styleSheets.lineHeight, style => style.lineHeight = `${lineHeight}`);
}

export function setTaskMarkerStyle(enabled: boolean) {
  if (styleSheets.taskMarker === undefined) {
    styleSheets.taskMarker = createStyleSheet('.cm-md-taskMarker { cursor: pointer }');
  }

  styleSheets.taskMarker.disabled = !enabled;
}

export function setGutterHovered(hovered: boolean) {
  const className = 'cm-gutterHover';
  const gutterDOM = document.querySelector('.cm-foldGutter') as HTMLElement | null;

  if (hovered && !globalState.hasModalSheet) {
    gutterDOM?.classList.add(className);
  } else {
    gutterDOM?.classList.remove(className);
  }

  globalState.gutterHovered = hovered;
  adjustGutterPositions('gutterHover');
}

function enableGutterHoverEffects() {
  const gutterDOM = document.querySelector('.cm-gutters') as HTMLElement | null;
  if (gutterDOM === null) {
    return;
  }

  if (storage.mouseLeaveHandler !== undefined) {
    gutterDOM.removeEventListener('mouseleave', storage.mouseLeaveHandler);
  }

  if (storage.mouseEnterHandler !== undefined) {
    gutterDOM.removeEventListener('mouseenter', storage.mouseEnterHandler);
  }

  // Instead of using the :hover pseudo class,
  // which is not reliable on WebKit when releasing the mouse outside the window,
  // we handle hover state manually and expose methods to native.
  storage.mouseLeaveHandler = () => setGutterHovered(false);
  storage.mouseEnterHandler = () => {
    if (!isMouseDown()) {
      setGutterHovered(true);
    }
  };

  gutterDOM.addEventListener('mouseleave', storage.mouseLeaveHandler);
  gutterDOM.addEventListener('mouseenter', storage.mouseEnterHandler);

  // Delay setting the transition to work around the issue mentioned in #436
  const foldGutter = document.querySelector('.cm-foldGutter') as HTMLElement | null;
  if (foldGutter !== null) {
    foldGutter.style.transition = '0.4s';
    foldGutter.style.transitionDelay = '0.1s';
  }
}

function createStyleSheet(styleText: string, enabled = true) {
  const style = document.createElement('style');
  document.head.appendChild(style);

  style.textContent = styleText;
  style.disabled = !enabled;

  return style;
}

const storage: {
  mouseLeaveHandler: (() => void) | undefined;
  mouseEnterHandler: (() => void) | undefined;
} = {
  mouseLeaveHandler: undefined,
  mouseEnterHandler: undefined,
};
