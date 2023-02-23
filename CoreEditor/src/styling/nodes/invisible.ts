import { Decoration, highlightTrailingWhitespace } from '@codemirror/view';
import { Compartment } from '@codemirror/state';
import { syntaxTree } from '@codemirror/language';
import { NodeType } from '@lezer/common';
import { InvisiblesBehavior } from '../../config';
import { calculateFontSize } from './heading';
import { createMarkDeco } from '../matchers/regex';
import { createDecoPlugin } from '../helper';
import { selectedTextDecoration } from './selection';
import { frontMatterRange } from '../../modules/frontMatter';
import { startEffect, stopEffect } from '../matchers/stateful';

// Originally learned from: https://github.com/ChromeDevTools/devtools-frontend/blob/main/front_end/ui/components/text_editor/config.ts
//
// We don't use the built-in highlightWhitespace extension,
// because it doesn't take custom font size into account.
//
// In Markdown rendering, we have different font sizes for headers,
// we need to figure out proper font size and set it to the pseudo class.
const renderInvisibles = createDecoPlugin(() => {
  return createMarkDeco(/\t| +/g, (match, pos) => {
    // If it's before the main caret and always show invisibles, we simply skip.
    //
    // The reason behind this is that <span> elements created for invisibles can break autocorrect features,
    // see `renderWhitespaceBeforeCaret` regarding how we draw this special whitespace.
    const invisible = match[0];
    if (alwaysRenderInvisibles() && invisible === ' ' && pos === window.editor.state.selection.main.anchor - 1) {
      return null;
    }

    return getOrCreateDeco(invisible, pos);
  });
});

// This function renders the space before the main caret "lazily".
//
// The reason we need this special rendering logic is that <span> elements can mess up autocorrect features,
// with some delay can make sure autocorrect work.
export function renderWhitespaceBeforeCaret() {
  if (!alwaysRenderInvisibles()) {
    return;
  }

  if (storage.lazyCompartment !== undefined) {
    stopEffect([storage.lazyCompartment]);
    storage.lazyCompartment = undefined;
  }

  if (storage.lazyRenderer !== undefined) {
    clearTimeout(storage.lazyRenderer);
    storage.lazyRenderer = undefined;
  }

  storage.lazyRenderer = setTimeout(() => {
    const editor = window.editor;
    const doc = editor.state.doc;

    const to = editor.state.selection.main.anchor;
    const from = to - 1;
    const caret = doc.sliceString(from, to);
    const spaces = doc.sliceString(from - 1, to + 1);

    // Example valid patterns: " (caret)", "x (caret)", "x (caret)y".
    if (from >= 0 && caret === ' ' && (/^[^ ]? $/.test(spaces) || /^[^ ] [^ ]$/.test(spaces))) {
      const deco = getOrCreateDeco(' ', from);
      storage.lazyCompartment = new Compartment;
      startEffect(storage.lazyCompartment, Decoration.set(deco.range(from, to)));
    }
  }, 5);
}

export function invisiblesExtension(behavior: InvisiblesBehavior, hasSelection: boolean) {
  if (behavior === InvisiblesBehavior.always) {
    return renderInvisibles;
  }

  if (behavior === InvisiblesBehavior.selection) {
    return hasSelection ? [renderInvisibles, selectedTextDecoration] : selectedTextDecoration;
  }

  if (behavior === InvisiblesBehavior.trailing) {
    return highlightTrailingWhitespace();
  }

  return [];
}

function alwaysRenderInvisibles() {
  return window.config.invisiblesBehavior === InvisiblesBehavior.always;
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
  lazyRenderer: ReturnType<typeof setTimeout> | undefined;
  lazyCompartment: Compartment | undefined;
} = {
  cachedDecos: new Map<string, Decoration>(),
  lazyRenderer: undefined,
  lazyCompartment: undefined,
};
