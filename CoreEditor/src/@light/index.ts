import { EditorView, highlightSpecialChars } from '@codemirror/view';
import { Compartment, EditorState } from '@codemirror/state';
import { markdown, markdownLanguage } from '../@vendor/lang-markdown';

import { Config } from '../config';
import { setUp, setTheme } from '../styling/config';
import { classHighlighters, markdownExtensions, renderExtensions } from '../styling/markdown';
import { scrollIntoView } from '../modules/selection';

import GitHubLight from '../styling/themes/github-light';
import GitHubDark from '../styling/themes/github-dark';

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
  EditorState.transactionFilter.of(tr => tr.docChanged ? [] : tr),
  EditorView.lineWrapping,

  // Markdown
  markdown({
    base: markdownLanguage,
    extensions: markdownExtensions,
  }),

  // Styling
  classHighlighters,
  theme.of(loadTheme(config.theme)),
  renderExtensions,
];

const doc = config.text;
const parent = document.querySelector('#editor') ?? document.body;

window.editor = new EditorView({ doc, parent, extensions });
setUp(config, loadTheme(config.theme).colors);

// Makes sure the content doesn't have unwanted inset
scrollIntoView(0);

// To keep the app size smaller, we don't have bridge here,
// inject function to window directly.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const bridge = window as any;
const storage: { scrollbarOffset?: number } = {};

bridge.setTheme = (name: string) => {
  setTheme(loadTheme(name));
};

bridge.startDragging = (location: number) => {
  // scrollbarOffset is the distance between the top of the scrollbar and the mouse location
  const { scrollbarTop, scrollbarHeight } = scrollerGeometryValues();
  storage.scrollbarOffset = location - scrollbarTop;

  // When it's outside the scrollbar, scroll smoothly to that position,
  // note this might not be 100% accurate as CodeMirror render the document lazily,
  // long documents may not have correct scrollHeight at the moment.
  if (location < scrollbarTop || location > scrollbarTop + scrollbarHeight) {
    scrollToMouseLocation(location, scrollbarHeight * 0.5, 'smooth');
  }
};

bridge.updateDragging = (location: number) => {
  if (storage.scrollbarOffset !== undefined) {
    scrollToMouseLocation(location, storage.scrollbarOffset);
  }
};

bridge.cancelDragging = () => {
  storage.scrollbarOffset = undefined;
};

// There're only two themes in the preview extension,
// use a simplified "loadTheme" to avoid bundling unused themes.
function loadTheme(name: string) {
  if (name === 'github-dark') {
    return GitHubDark();
  } else {
    return GitHubLight();
  }
}

function scrollToMouseLocation(location: number, scrollbarOffset: number, behavior: ScrollBehavior = 'auto') {
  // Basically, the scrollbar needs to move with the mouse position,
  // we need to take the initial scrollbar offset into account.
  const { clientHeight, scrollHeight, scrollbarHeight } = scrollerGeometryValues();
  const percentage = (location - scrollbarOffset) / (clientHeight - scrollbarHeight);
  window.scrollTo({
    top: percentage * (scrollHeight - clientHeight),
    behavior,
  });
}

function scrollerGeometryValues() {
  const container = document.documentElement;
  const clientHeight = container.clientHeight;
  const scrollHeight = container.scrollHeight;
  const scrollbarHeight = clientHeight * (clientHeight / container.offsetHeight);

  const progress = container.scrollTop / (container.scrollHeight - clientHeight);
  const scrollbarTop = progress * (clientHeight - scrollbarHeight);

  return { clientHeight, scrollHeight, scrollbarHeight, scrollbarTop };
}
