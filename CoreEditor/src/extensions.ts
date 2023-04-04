import {
  EditorView,
  highlightSpecialChars,
  drawSelection,
  dropCursor,
  rectangularSelection,
  crosshairCursor,
  highlightActiveLine,
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
import { gutterExtensions } from './styling/nodes/gutter';

import { localizePhrases } from './modules/localization';
import { indentationKeymap } from './modules/indentation';
import { wordTokenizer, observeChanges, interceptInputs } from './modules/input';
import { tocKeymap } from './modules/toc';

const theme = new Compartment;
const gutters = new Compartment;
const invisibles = new Compartment;
const activeLine = new Compartment;
const selectedLines = new Compartment;
const lineWrapping = new Compartment;
const lineEndings = new Compartment;
const indentUnit = new Compartment;

window.dynamics = {
  theme,
  gutters,
  invisibles,
  activeLine,
  selectedLines,
  lineWrapping,
  lineEndings,
  indentUnit,
};

interface Options {
  lineBreak?: string;
}

export function minimal(options: Options) {
  return [
    ...core(options),
    markdown({ base: markdownLanguage, extensions: markdownExtensions }),
  ];
}

// Make this a function because some resources (e.g., phrases) require lazy loading
export function full(options: Options) {
  return [
    // Basic
    ...core(options),
    highlightSpecialChars(),
    history(),
    dropCursor(),
    EditorState.allowMultipleSelections.of(true),
    indentUnit.of(window.config.indentUnit !== undefined ? indentUnitFacet.of(window.config.indentUnit) : []),
    indentOnInput(),
    bracketMatching(),
    closeBrackets(),
    rectangularSelection(),
    crosshairCursor(),
    highlightActiveLineGutter(),
    highlightSelectionMatches(),
    localizePhrases(),

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
    invisibles.of([]),
    selectedLines.of([]),
    actionExtensions,

    // Input handling
    wordTokenizer(),
    interceptInputs(),
    observeChanges(),
  ];
}

function core(options: Options) {
  return [
    drawSelection(),
    lineEndings.of(options.lineBreak !== undefined ? EditorState.lineSeparator.of(options.lineBreak) : []),
    lineWrapping.of(window.config.lineWrapping ? EditorView.lineWrapping : []),
    gutters.of(window.config.showLineNumbers ? gutterExtensions : []),
    activeLine.of(window.config.showActiveLineIndicator ? highlightActiveLine() : []),
    theme.of(loadTheme(window.config.theme)),
    renderExtensions,
  ];
}
