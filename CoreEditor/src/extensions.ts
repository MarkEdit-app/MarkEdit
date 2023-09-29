import {
  EditorView,
  highlightSpecialChars,
  drawSelection,
  dropCursor,
  rectangularSelection,
  crosshairCursor,
  highlightActiveLineGutter,
  keymap,
} from '@codemirror/view';

import { Compartment, EditorState } from '@codemirror/state';
import { indentUnit as indentUnitFacet, indentOnInput, bracketMatching, foldKeymap } from '@codemirror/language';
import { history, defaultKeymap, historyKeymap } from '@codemirror/commands';
import { highlightSelectionMatches, search } from '@codemirror/search';
import { closeBrackets, closeBracketsKeymap } from '@codemirror/autocomplete';
import { markdown, markdownLanguage } from './@vendor/lang-markdown';
import { languages } from './@vendor/language-data';

import { loadTheme } from './styling/themes';
import { markdownExtensions, renderExtensions, actionExtensions } from './styling/markdown';
import { lineIndicatorLayer } from './styling/nodes/line';
import { gutterExtensions } from './styling/nodes/gutter';

import { localizePhrases } from './modules/localization';
import { indentationKeymap } from './modules/indentation';
import { wordTokenizer, observeChanges, interceptInputs } from './modules/input';
import { tocKeymap } from './modules/toc';

// Read-only mode
import { inlineCodeStyle, codeBlockStyle } from './styling/nodes/code';
import { tableStyle } from './styling/nodes/table';
import { frontMatterStyle } from './styling/nodes/frontMatter';
import { highlightDiffs } from './styling/nodes/diff';

const theme = new Compartment;
const gutters = new Compartment;
const invisibles = new Compartment;
const activeLine = new Compartment;
const selectedLines = new Compartment;
const lineWrapping = new Compartment;
const lineEndings = new Compartment;
const indentUnit = new Compartment;
const selectionHighlight = new Compartment;

window.dynamics = {
  theme,
  gutters,
  invisibles,
  activeLine,
  selectedLines,
  lineWrapping,
  lineEndings,
  indentUnit,
  selectionHighlight,
};

// Make this a function because some resources (e.g., phrases) require lazy loading
export function extensions(options: {
  readOnly: boolean;
  lineBreak?: string;
}) {
  if (options.readOnly) {
    return readOnlyExtensions();
  } else {
    return fullExtensions(options);
  }
}

function fullExtensions(options: { lineBreak?: string }) {
  return [
    // Basic
    highlightSpecialChars(),
    history(),
    drawSelection(),
    dropCursor(),
    EditorState.allowMultipleSelections.of(true),
    indentUnit.of(window.config.indentUnit !== undefined ? indentUnitFacet.of(window.config.indentUnit) : []),
    indentOnInput(),
    bracketMatching(),
    closeBrackets(),
    rectangularSelection(),
    crosshairCursor(),
    activeLine.of(window.config.showActiveLineIndicator ? lineIndicatorLayer : []),
    highlightActiveLineGutter(),
    selectionHighlight.of(highlightSelectionMatches()),
    localizePhrases(),

    // Line behaviors
    lineEndings.of(options.lineBreak !== undefined ? EditorState.lineSeparator.of(options.lineBreak) : []),
    gutters.of(window.config.showLineNumbers ? gutterExtensions : []),
    lineWrapping.of(window.config.lineWrapping ? EditorView.lineWrapping : []),

    // Search
    search({
      createPanel() {
        class DummyPanel { dom = document.createElement('span'); }
        return new DummyPanel();
      },
    }),

    // Keymap
    keymap.of([
      // We use cmd-i to toggle italic
      ...defaultKeymap.filter(keymap => keymap.key !== 'Mod-i'),
      ...historyKeymap,
      ...closeBracketsKeymap,
      ...foldKeymap,
      // By default CodeMirror disables tab (character) insertion (https://codemirror.net/examples/tab/),
      // however, MarkEdit runs on a WebView instead of browsers, we do want to bind the tab key.
      ...indentationKeymap,
      ...tocKeymap,
    ]),

    // Markdown
    markdown({
      base: markdownLanguage,
      codeLanguages: languages,
      extensions: markdownExtensions,
    }),

    // Styling
    theme.of(loadTheme(window.config.theme)),
    invisibles.of([]),
    selectedLines.of([]),
    renderExtensions,
    actionExtensions,

    // Input handling
    wordTokenizer(),
    interceptInputs(),
    observeChanges(),
  ];
}

/**
 * The minimum set of extensions used in read-only mode.
 *
 * Don't share the code with @light builds, which increase the bundle size.
 */
function readOnlyExtensions() {
  return [
    // Basic
    highlightSpecialChars(),
    EditorView.editable.of(false),
    EditorState.readOnly.of(true),

    // Line behaviors
    gutters.of(window.config.showLineNumbers ? gutterExtensions : []),
    lineWrapping.of(window.config.lineWrapping ? EditorView.lineWrapping : []),

    // Markdown
    markdown({
      base: markdownLanguage,
      extensions: markdownExtensions,
    }),

    // Styling
    theme.of(loadTheme(window.config.theme)),
    inlineCodeStyle,
    codeBlockStyle,
    tableStyle,
    frontMatterStyle,
    highlightDiffs,
  ];
}
