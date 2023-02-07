import { EditorView, highlightSpecialChars } from '@codemirror/view';
import { Compartment, EditorState } from '@codemirror/state';
import { markdown, markdownLanguage } from '../@vendor/lang-markdown';

import { Config } from '../config';
import { markdownExtensions, renderExtensions } from '../styling/markdown';

import { loadTheme } from '../styling/themes';
import * as styling from '../styling/config';

// "{{EDITOR_CONFIG}}" will be replaced with a JSON literal
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const config: Config = '{{EDITOR_CONFIG}}' as any;
window.config = config;

const theme = new Compartment;
window.dynamics = { theme };

const extensions = [
  // Basic
  highlightSpecialChars(),
  EditorView.editable.of(false),
  EditorState.readOnly.of(true),
  EditorView.lineWrapping,

  // Markdown
  markdown({
    base: markdownLanguage,
    extensions: markdownExtensions,
  }),

  // Styling
  theme.of(loadTheme(config.theme)),
  renderExtensions,
];

const doc = config.text;
const parent = document.querySelector('#editor') ?? document.body;

window.editor = new EditorView({ doc, parent, extensions });
styling.setUp(config);

// To keep the app size smaller, we don't have bridge here,
// inject function to window directly.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
(window as any).setTheme = (name: string) => {
  styling.setTheme(loadTheme(name));
};
