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
import { defaultKeymap } from '@codemirror/commands';
import { highlightSelectionMatches, search } from '@codemirror/search';
import { closeBrackets, closeBracketsKeymap } from '@codemirror/autocomplete';
import { markdown, markdownLanguage } from './@vendor/lang-markdown';
import { languages } from './@vendor/language-data';
import { history, historyKeymap } from './@vendor/commands/history';

import { loadTheme } from './styling/themes';
import { classHighlighters, markdownExtensions, renderExtensions, actionExtensions } from './styling/markdown';
import { lineIndicatorLayer } from './styling/nodes/line';
import { paragraphIndentStyle, lineIndentStyle } from './styling/nodes/indent';
import { gutterExtensions } from './styling/nodes/gutter';

import { isActive as isWritingToolsActive } from './modules/writingTools';
import { localizePhrases } from './modules/localization';
import { indentationKeymap } from './modules/indentation';
import { wordTokenizer, observeChanges, interceptInputs } from './modules/input';
import { tocKeymap } from './modules/toc';
import { userExtensions, userMarkdownConfigs, userCodeLanguages } from './api/methods';

// Revision mode
import { inlineCodeStyle, codeBlockStyle } from './styling/nodes/code';
import { tableStyle } from './styling/nodes/table';
import { frontMatterStyle } from './styling/nodes/frontMatter';
import { highlightDiffs } from './styling/nodes/diff';

const theme = new Compartment;
const readOnly = new Compartment;
const gutters = new Compartment;
const invisibles = new Compartment;
const activeLine = new Compartment;
const selectedLines = new Compartment;
const lineWrapping = new Compartment;
const lineEndings = new Compartment;
const indentUnit = new Compartment;
const selectionHighlight = new Compartment;
const extensionConfigurator = new Compartment;
const markdownConfigurator = new Compartment;

window.dynamics = {
  theme,
  readOnly,
  gutters,
  invisibles,
  activeLine,
  selectedLines,
  lineWrapping,
  lineEndings,
  indentUnit,
  selectionHighlight,
  extensionConfigurator,
  markdownConfigurator,
};

// Make this a function because some resources (e.g., phrases) require lazy loading
export function extensions(options: {
  revisionMode: boolean;
  lineBreak?: string;
}) {
  if (options.revisionMode) {
    return revisionExtensions();
  } else {
    return fullExtensions(options);
  }
}

export function markdownConfigurations() {
  return markdown({
    base: markdownLanguage,
    codeLanguages: [
      ...languages,
      ...userCodeLanguages(),
    ],
    extensions: [
      ...markdownExtensions,
      ...userMarkdownConfigs(),
    ],
  });
}

function fullExtensions(options: { lineBreak?: string }) {
  return [
    // Extensions created by user scripts
    extensionConfigurator.of(userExtensions()),

    // Read-only
    readOnly.of(window.config.readOnlyMode ? [EditorView.editable.of(false), EditorState.readOnly.of(true)] : []),
    EditorState.transactionFilter.of(transaction => {
      if (window.config.readOnlyMode && transaction.docChanged) {
        return [];
      } else {
        return transaction;
      }
    }),

    // Basic
    highlightSpecialChars(),
    history({ ignoreBeforeInput: () => isWritingToolsActive() }),
    drawSelection({ cursorBlinkRate: 1000 }),
    dropCursor(),
    EditorState.allowMultipleSelections.of(true),
    indentUnit.of(window.config.indentUnit !== undefined ? indentUnitFacet.of(window.config.indentUnit) : []),
    indentOnInput(),
    bracketMatching(),
    window.config.autoCharacterPairs ? closeBrackets() : [],
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
    indentBehaviorExtension(),

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
    markdownConfigurator.of(markdownConfigurations()),

    // Styling
    classHighlighters,
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
 * The minimum set of extensions used in revision mode.
 *
 * Don't share the code with @light builds, which increase the bundle size.
 */
function revisionExtensions() {
  return [
    // Basic
    highlightSpecialChars(),
    EditorView.editable.of(false),
    EditorState.readOnly.of(true),
    EditorState.transactionFilter.of(tr => tr.docChanged ? [] : tr),

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

function indentBehaviorExtension() {
  switch (window.config.indentBehavior) {
    case 'paragraph': return paragraphIndentStyle;
    case 'line': return lineIndentStyle;
    default: return [];
  }
}
