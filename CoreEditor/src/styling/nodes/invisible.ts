import { Decoration, highlightTrailingWhitespace } from '@codemirror/view';
import { syntaxTree } from '@codemirror/language';
import { NodeType } from '@lezer/common';
import { InvisiblesBehavior } from '../../config';
import { calculateFontSize } from './heading';
import { createMarkDeco } from '../matchers/regex';
import { createDecoPlugin } from '../helper';
import { selectedTextDecoration } from './selection';
import { frontMatterRange } from '../../modules/frontMatter';
import { refreshEditFocus } from '../../modules/selection';

const typingInterval = 300;
const focusUpdateInterval = 15;

// The difference is that renderInvisiblesSelection doesn't match continuous spaces,
// which doesn't work well with selectedTextDecoration because nodes can be nested.
const renderInvisiblesAlways = renderInvisibles(/\t| +/g);
const renderInvisiblesSelection = renderInvisibles(/\t| /g);

export function invisiblesExtension(behavior: InvisiblesBehavior, hasSelection: boolean) {
  if (behavior === InvisiblesBehavior.always) {
    return renderInvisiblesAlways;
  }

  if (behavior === InvisiblesBehavior.selection) {
    // renderInvisiblesSelection must go before selectedTextDecoration
    return hasSelection ? [renderInvisiblesSelection, selectedTextDecoration] : selectedTextDecoration;
  }

  if (behavior === InvisiblesBehavior.trailing) {
    return highlightTrailingWhitespace();
  }

  return [];
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
function renderInvisibles(regexp: RegExp) {
  return createDecoPlugin(() => createMarkDeco(regexp, (match, pos) => {
    const invisible = match[0];

    // If we always show invisibles and just inserted a whitespace, we skip drawing in this render pass.
    //
    // The reason behind this is that <span> elements created for invisibles can break autocorrect features,
    // we will redraw the skipped whitespace in renderWhitespaceBeforeCaret.
    if (
      (alwaysRenderInvisibles()) &&
      (invisible === ' ') &&
      (Date.now() - storage.spaceInsertedTime < typingInterval) &&
      (pos === caretTextPosition() - 1)
    ) {
      return null;
    }

    return getOrCreateDeco(invisible, pos);
  }));
}

function alwaysRenderInvisibles() {
  return window.config.invisiblesBehavior === InvisiblesBehavior.always;
}

function caretTextPosition() {
  return window.editor.state.selection.main.anchor;
}

/**
 * Get or create a deco for given invisible character at a position.
 */
function getOrCreateDeco(invisible: string, pos: number) {
  const fontSize = (() => {
    const range = frontMatterRange();
    if (range !== undefined && pos >= range.from && pos <= range.to) {
      return window.config.fontSize;
    }

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
      'content': '·‌'.repeat(invisible.length),
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
