import { EditorView, highlightSpecialChars } from '@codemirror/view';
import { Compartment, EditorState } from '@codemirror/state';
import { markdown, markdownLanguage } from '../@vendor/lang-markdown';

import { Config } from '../config';
import { markdownExtensions, renderExtensions } from '../styling/markdown';

import GitHubLight from '../styling/themes/github-light';
import GitHubDark from '../styling/themes/github-dark';

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
styling.setUp(config, loadTheme(config.theme).accentColor);

// Track scroll progress because we don't have scrollView in WKWebView on macOS
scrollDidChange();
document.addEventListener('scroll', scrollDidChange);

// To keep the app size smaller, we don't have bridge here,
// inject function to window directly.
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const bridge = (window as any);
const storage: { scrollbarOffset?: number } = {};

bridge.setTheme = (name: string) => {
  styling.setTheme(loadTheme(name));
};

bridge.startDragging = (location: number) => {
  // scrollbarOffset is the distance between the top of the scrollbar and the mouse location
  const { scrollbarTop } = scrollerGeometryValues();
  storage.scrollbarOffset = location - scrollbarTop;
};

bridge.updateDragging = (location: number) => {
  if (storage.scrollbarOffset === undefined) {
    return;
  }

  // Basically, the scrollbar needs to move with the mouse position,
  // we need to take the initial scrollbar offset into account.
  const { clientHeight, scrollHeight, scrollbarHeight } = scrollerGeometryValues();
  const percentage = (location - storage.scrollbarOffset) / (clientHeight - scrollbarHeight);
  window.scrollTo({ top: percentage * (scrollHeight - clientHeight) });
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

function scrollDidChange() {
  const { scrollbarHeight, scrollbarTop } = scrollerGeometryValues();
  window.webkit?.messageHandlers?.bridge?.postMessage({
    top: scrollbarTop,
    bottom: scrollbarTop + scrollbarHeight,
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
