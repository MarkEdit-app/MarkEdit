import { Decoration, highlightTrailingWhitespace } from '@codemirror/view';
import { syntaxTree } from '@codemirror/language';
import { NodeType } from '@lezer/common';
import { InvisiblesBehavior } from '../../config';
import { calculateFontSize } from './heading';
import { createMarkDeco } from '../matchers/regex';
import { createDecoPlugin } from '../helper';
import { editingState } from '../../common/store';
import { selectedTextDecoration } from './selection';
import { frontMatterRange } from '../../modules/frontMatter';

// Originally learned from: https://github.com/ChromeDevTools/devtools-frontend/blob/main/front_end/ui/components/text_editor/config.ts
//
// We don't use the built-in highlightWhitespace extension,
// because it doesn't take custom font size into account.
//
// In Markdown rendering, we have different font sizes for headers,
// we need to figure out proper font size and set it to the pseudo class.
const renderInvisibles = createDecoPlugin(() => {
  return createMarkDeco(/\t| +/g, (match, pos) => {
    const invisible = match[0];
    const currentTime = Date.now();

    // If we always show invisibles and just inserted a whitespace, we simply skip.
    //
    // The reason behind this is that <span> elements created for invisibles can break autocorrect features,
    // we will resume the skipped rendering in EditorView.updateListener.
    if (alwaysRenderInvisibles() && invisible === ' ' && (currentTime - editingState.keystrokeTime < 500) && pos === window.editor.state.selection.main.anchor - 1) {
      editingState.invisibleSkippedTime = currentTime;
      return null;
    }

    return getOrCreateDeco(invisible, pos);
  });
});

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
} = {
  cachedDecos: new Map<string, Decoration>(),
};
