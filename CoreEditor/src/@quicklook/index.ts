import { EditorView, highlightSpecialChars } from '@codemirror/view';
import { Compartment, EditorState } from '@codemirror/state';
import { markdown, markdownLanguage } from '@codemirror/lang-markdown';
import { html } from '@codemirror/lang-html';
import { yamlFrontmatter as frontMatter } from '@codemirror/lang-yaml';

import { Config } from '../config';
import { bundledLanguages } from '../languages';
import { setUp, setTheme } from '../styling/config';
import { classHighlighters, markdownExtensions, renderExtensions } from '../styling/markdown';
import { linkStyles } from '../styling/nodes/link';
import { scrollIntoView } from '../modules/selection';
import { enablePinchZoom, PinchZoomTarget } from './zoom';

import GitHubLight from '../styling/themes/github-light';
import GitHubDark from '../styling/themes/github-dark';

// There's no native bridge in the QuickLook extension, functions live on window directly
declare global {
  interface Window {
    startDragging?: (location: number) => void;
    updateDragging?: (location: number) => void;
    cancelDragging?: () => void;
    pinchZoomTarget?: () => PinchZoomTarget | null;
  }
}

/**
 * Set up a read-only editor for the QuickLook extension.
 */
export function setUpQuickLook(config: Config) {
  // Opts in to the rules in @quicklook/index.css
  document.documentElement.classList.add('markedit-quicklook');

  const theme = new Compartment;
  window.dynamics = { theme };

  // Derive the theme from the system color scheme, the QuickLook extension has no other source
  const colorSchemeQuery = matchMedia('(prefers-color-scheme: dark)');
  const preferredTheme = () => colorSchemeQuery.matches ? GitHubDark() : GitHubLight();
  const initialTheme = preferredTheme();

  colorSchemeQuery.addEventListener('change', () => {
    setTheme(preferredTheme());
  });

  window.editor = new EditorView({
    doc: config.text,
    parent: document.querySelector('#editor') ?? document.body,
    extensions: [
      // Basic
      highlightSpecialChars(),
      EditorView.editable.of(false),
      EditorState.readOnly.of(true),
      EditorState.transactionFilter.of(tr => tr.docChanged ? [] : tr),
      EditorView.lineWrapping,

      // Markdown
      frontMatter({
        content: markdown({
          base: markdownLanguage,
          codeLanguages: bundledLanguages(html()),
          extensions: markdownExtensions,
          completeHTMLTags: false,
        }),
      }),

      // Styling
      classHighlighters,
      theme.of(initialTheme),
      renderExtensions,
      linkStyles,

      // Accessibility
      EditorView.contentAttributes.of({
        'role': 'textbox',
        'aria-multiline': 'true',
        'aria-readonly': 'true',
      }),
    ],
  });

  const colors = initialTheme.colors;
  setUp(config, colors);

  // Makes sure the content doesn't have unwanted inset
  scrollIntoView(0);
  enableDragGestures();
}

/**
 * Homemade scrollbar dragging, driven by mouse events forwarded from native.
 */
function enableDragGestures() {
  const bridge = window;
  bridge.startDragging = (original: number) => {
    // scrollbarOffset is the distance between the top of the scrollbar and the mouse location
    const location = convertToLocal(original);
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
      scrollToMouseLocation(convertToLocal(location), storage.scrollbarOffset);
    }
  };

  bridge.cancelDragging = () => {
    storage.scrollbarOffset = undefined;
  };

  // Zoom in and out using the trackpad
  enablePinchZoom(bridge);
}

function scrollerElement(): HTMLElement | null {
  return document.querySelector<HTMLElement>('.cm-scroller');
}

function scrollToMouseLocation(location: number, scrollbarOffset: number, behavior: ScrollBehavior = 'auto') {
  // Basically, the scrollbar needs to move with the mouse position,
  // we need to take the initial scrollbar offset into account.
  const { clientHeight, scrollHeight, scrollbarHeight } = scrollerGeometryValues();
  const percentage = (location - scrollbarOffset) / (clientHeight - scrollbarHeight);
  (scrollerElement() ?? document.documentElement).scrollTo({
    top: percentage * (scrollHeight - clientHeight),
    behavior,
  });
}

/**
 * Convert the viewport Y coordinate to the local coordinate relative to the scroller's top.
 */
function convertToLocal(viewportY: number): number {
  const scroller = scrollerElement();
  return scroller === null ? viewportY : viewportY - scroller.getBoundingClientRect().top;
}

function scrollerGeometryValues() {
  const container = scrollerElement() ?? document.documentElement;
  const clientHeight = container.clientHeight;
  const scrollHeight = container.scrollHeight;
  const scrollbarHeight = clientHeight * (clientHeight / scrollHeight);

  const progress = container.scrollTop / (container.scrollHeight - clientHeight);
  const scrollbarTop = progress * (clientHeight - scrollbarHeight);

  return { clientHeight, scrollHeight, scrollbarHeight, scrollbarTop };
}

const storage: { scrollbarOffset?: number } = {};
