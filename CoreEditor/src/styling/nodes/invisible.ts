import { Decoration, highlightTrailingWhitespace } from '@codemirror/view';
import { syntaxTree } from '@codemirror/language';
import { NodeType } from '@lezer/common';
import { InvisiblesBehavior } from '../../config';
import { calculateFontSize } from './heading';
import { createMarkDeco } from '../matchers/regex';
import { createDecoPlugin } from '../helper';
import { isPositionFolded } from './gutter';
import { selectedVisiblesDecoration } from './selection';
import { refreshEditFocus } from '../../modules/selection';
import { getVisibleLines } from '../../modules/lines';
import { LineBreakWidget } from '../views';

const typingInterval = 300;
const focusUpdateInterval = 15;

// Extensions to render whitespaces
const renderInvisiblesAlways = renderInvisibles(/\t| +/g, false);
const renderInvisiblesSelection = renderInvisibles(/\t| /g, true); // Don't match continuous spaces, selectedVisiblesDecoration won't work

// Extensions to render line breaks
const renderLineBreaksAlways = renderLineBreaks(false);
const renderLineBreaksSelection = renderLineBreaks(true);

export function invisiblesExtension(behavior: InvisiblesBehavior, hasSelection: boolean) {
  if (behavior === InvisiblesBehavior.always) {
    return [renderInvisiblesAlways, renderLineBreaksAlways];
  }

  if (behavior === InvisiblesBehavior.selection) {
    // renderInvisiblesSelection must go before selectedVisiblesDecoration
    return hasSelection ? [renderInvisiblesSelection, renderLineBreaksSelection, selectedVisiblesDecoration] : selectedVisiblesDecoration;
  }

  if (behavior === InvisiblesBehavior.trailing) {
    return highlightTrailingWhitespace();
  }

  return [];
}

export function alwaysRenderInvisibles() {
  return window.config.invisiblesBehavior === InvisiblesBehavior.always;
}

// This function renders the space before the main caret by forcing a focus change.
//
// The reason we need this special rendering logic is that <span> elements can mess up autocorrect features,
// with some delay can make sure autocorrect work.
export function renderWhitespaceBeforeCaret() {
  if (!alwaysRenderInvisibles()) {
    return;
  }

  storage.spaceInsertedTime = Date.now();
  const pos = caretTextPosition();

  // We don't need to care about consecutive spaces
  if (window.editor.state.sliceDoc(pos - 1, pos) === ' ') {
    return;
  }

  if (storage.focusUpdater !== undefined) {
    clearTimeout(storage.focusUpdater);
    storage.focusUpdater = undefined;
  }

  storage.focusUpdater = setTimeout(() => {
    storage.spaceInsertedTime = 0;
    refreshEditFocus();
  }, focusUpdateInterval);
}

// Originally learned from: https://github.com/ChromeDevTools/devtools-frontend/blob/main/front_end/ui/components/text_editor/config.ts
//
// We don't use the built-in highlightWhitespace extension,
// because it doesn't take custom font size into account.
//
// In Markdown rendering, we have different font sizes for headers,
// we need to figure out proper font size and set it to the pseudo class.
function renderInvisibles(regexp: RegExp, selectionOnly: boolean) {
  return createDecoPlugin(() => createMarkDeco(regexp, (match, pos) => {
    // If it's for selection only and the position is not in any selection,
    // we won't show the invisible.
    if (shouldIgnorePosition(pos, selectionOnly)) {
      return null;
    }

    // If we always show invisibles and just inserted a whitespace, we skip drawing in this render pass.
    //
    // The reason behind this is that <span> elements created for invisibles can break autocorrect features,
    // we will redraw the skipped whitespace in renderWhitespaceBeforeCaret.
    const invisible = match[0];
    if (
      (alwaysRenderInvisibles()) &&
      (invisible === ' ') &&
      (Date.now() - storage.spaceInsertedTime < typingInterval) &&
      (pos === caretTextPosition() - 1)
    ) {
      return null;
    }

    // Disable decoration for empty rendering
    if (invisible === ' ' && window.config.visibleWhitespaceCharacter === '') {
      return null;
    }

    return getOrCreateDeco(invisible, pos);
  }));
}

function renderLineBreaks(selectionOnly: boolean) {
  return createDecoPlugin(() => {
    // Disable decoration for empty rendering
    if (window.config.visibleLineBreakCharacter === '') {
      return Decoration.none;
    }

    const decos = getVisibleLines()
      .map(({ to: pos }) => {
        if (shouldIgnorePosition(pos, selectionOnly)) {
          return null;
        }

        if (window.config.showLineNumbers && isPositionFolded(pos)) {
          return null;
        }

        const widget = new LineBreakWidget(pos);
        return Decoration.widget({ widget, side: 1 }).range(pos);
      })
      .filter(deco => deco !== null);

    return Decoration.set(decos);
  });
}

function caretTextPosition() {
  return window.editor.state.selection.main.anchor;
}

function shouldIgnorePosition(pos: number, selectionOnly: boolean) {
  if (selectionOnly) {
    const ranges = window.editor.state.selection.ranges;
    return !ranges.some(range => range.from <= pos && range.to > pos);
  }

  return false;
}

/**
 * Get or create a deco for given invisible character at a position.
 */
function getOrCreateDeco(invisible: string, pos: number) {
  const fontSize = (() => {
    const state = window.editor.state;
    const node = syntaxTree(state).resolve(pos);
    return calculateFontSize(window.config.fontSize, headingLevel(node.type));
  })();

  const key = invisible + fontSize;
  const cachedDeco = storage.cachedDecos.get(key);

  // Great, exactly the same deco was created before
  if (cachedDeco !== undefined) {
    return cachedDeco;
  }

  const fontStyle = (() => {
    if (fontSize <= window.config.fontSize) {
      // Only enable special style for Markdown headings where bigger font sizes are used
      return '';
    }

    return `font-size: ${fontSize}px`;
  })();

  const newDeco = Decoration.mark({
    attributes: invisible === '\t' ? { 'class': 'cm-visibleTab' } : {
      'class': 'cm-visibleSpace',
      'style': fontStyle,
      'content': (window.config.visibleWhitespaceCharacter ?? '·‌').repeat(invisible.length),
    },
  });

  storage.cachedDecos.set(key, newDeco);
  return newDeco;
}

// https://github.com/codemirror/lang-markdown/blob/main/src/markdown.ts
function headingLevel(type: NodeType) {
  const match = /^(?:ATX|Setext)Heading(\d)$/.exec(type.name);
  return match ? +match[1] : 0;
}

const storage: {
  cachedDecos: Map<string, Decoration>;
  focusUpdater: ReturnType<typeof setTimeout> | undefined;
  spaceInsertedTime: number;
} = {
  cachedDecos: new Map<string, Decoration>(),
  focusUpdater: undefined,
  spaceInsertedTime: 0,
};
