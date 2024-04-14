import { EditorView } from '@codemirror/view';
import { HighlightStyle, TagStyle, syntaxHighlighting } from '@codemirror/language';
import { Tag, tags as defaultTags } from '@lezer/highlight';
import { StyleSpec } from 'style-mod';
import { ColorScheme, EditorColors } from './types';
import { shadowableTextColor } from './helper';
import { isChrome } from '../common/env';

// Extend tags by adding Markdown-specific ones
const tags = {
  ...defaultTags,
  inlineCode: Tag.define(),
  codeInfo: Tag.define(),
  codeMark: Tag.define(),
  listMark: Tag.define(),
  quoteMark: Tag.define(),
  linkMark: Tag.define(),
  setextHeading1: Tag.define(),
  setextHeading2: Tag.define(),
};

// Here we define color independent theme styles,
// it's almost the built-in "baseTheme" concept in CodeMirror but provides more flexibility.
const sharedStyles: { [selector: string]: StyleSpec } = {
  // Default
  '.cm-content': {
    paddingRight: '12px',
    paddingBottom: '50vh',

    // CodeMirror uses border-left-color of cm-cursor to draw the caret,
    // we need to disable this as it draws an extra caret in macOS Sonoma.
    caretColor: 'transparent',
  },
  // Mimic the macOS Sonoma rounded caret
  '.cm-cursor': {
    borderLeftWidth: '2px',
    borderRadius: '1px',
  },
  // Mimic the macOS Sonoma caret breathing
  '&.cm-focused > .cm-scroller > .cm-cursorLayer': {
    animation: 'cm-blink infinite', // Remove the "steps(1)" to have fade effects
  },
  '@keyframes cm-blink': { '40%, 90%': { opacity: 1 }, '60%, 70%': { opacity: 0 } },
  '@keyframes cm-blink2': { '40%, 90%': { opacity: 1 }, '60%, 70%': { opacity: 0 } },
  '.cm-lineWrapping': {
    // Prefer pre-wrap over break-spaces because trailing whitespaces can lead to extra line breaks,
    // it can be an issue for whitespace rendering, especially for "selection" mode.
    whiteSpace: 'pre-wrap',
  },
  '.cm-focused': {
    outline: 'none',
  },
  '.cm-foldGutter': {
    padding: '0 4px',
    opacity: '0',
    transition: '0s', // See #436
    transitionDelay: '0s',
  },
  '.cm-foldGutter.cm-gutterHover': {
    opacity: '1',
  },
  '.cm-foldGutter, .cm-foldPlaceholder': {
    /* We don't use ui-monospace here because ▶︎ and ••• look very big */
    fontFamily: 'monospace',
  },
  '.cm-foldPlaceholder': {
    margin: '0 4px',
    padding: '0 4px',
    borderRadius: '4px',
    border: 'none',
  },
  '.cm-gutters': {
    borderRight: 'none',
    fontFamily: 'ui-monospace, monospace',
  },
  '.cm-activeLineGutter': {
    backgroundColor: 'inherit',
  },
  '.cm-snippetFieldPosition': {
    borderLeft: 'none',
  },
  // Extended
  '.cm-visibleTab': (() => {
    // Chrome right now doesn't support mask-image, prefix them with -webkit- for testing purpose
    const prefix = isChrome ? '-webkit-mask' : 'mask';
    const attributes: { [key: string]: string } = {};
    attributes[`${prefix}-image`] = 'url(\'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="20"><path stroke="%23888" stroke-width="1.2" fill="none" stroke-linecap="round" stroke-linejoin="round" d="M190.5 5l6 5m-6 5l6-5M1 10h195"/></svg>\')';
    attributes[`${prefix}-size`] = 'auto 100%';
    attributes[`${prefix}-position`] = 'right 90%';
    attributes[`${prefix}-repeat`] = 'no-repeat';
    return attributes;
  })(),
  '.cm-visibleSpace::before': {
    content: 'attr(content)',
    position: 'absolute',
    pointerEvents: 'none',
  },
  '.cm-md-monospace, .cm-md-monospace *, .cm-md-codeBlock *, .cm-md-table *': {
    fontFamily: 'ui-monospace, monospace',
  },
};

// Here we define color independent highlight styles
const sharedHighlights = [
  { tag: tags.strong, fontWeight: 'bolder' },
  { tag: [tags.emphasis, tags.quote], fontStyle: 'italic' },
  { tag: tags.strikethrough, textDecoration: 'line-through' },
  { tag: tags.link, textDecoration: 'underline' },
  { tag: tags.monospace, fontFamily: 'ui-monospace, monospace' },
];

function buildTheme(colors: EditorColors, scheme?: ColorScheme) {
  const specs: { [key: string]: StyleSpec } = {
    // Root
    '&': {
      color: colors.text,
      backgroundColor: colors.background,
    },
    '.cm-cursor, .cm-dropCursor': {
      borderLeftColor: colors.caret,
    },
    // Selection
    '&.cm-focused .cm-selectionBackground, .cm-selectionBackground, .cm-content ::selection': {
      backgroundColor: `${colors.selection} !important`, // #180 !important is needed by macOS 14 sdk
    },
    // Brackets
    '&.cm-focused .cm-matchingBracket, &.cm-focused .cm-nonmatchingBracket': {
      backgroundColor: colors.matchingBracket,
      boxShadow: buildInnerBorder(1.5, colors.bracketBorder),
    },
    // Gutters
    '.cm-gutters': {
      color: colors.lineNumber,
      backgroundColor: colors.background,
    },
    '.cm-lineNumbers > .cm-activeLineGutter': {
      color: colors.text,
    },
    // Handle of code folding
    '.cm-foldGutter, .cm-foldPlaceholder': {
      color: `${colors.text}66`,
    },
    '.cm-foldPlaceholder': {
      backgroundColor: colors.lighterBackground,
    },
    // Search
    '.cm-searchMatch': {
      backgroundColor: colors.searchMatch,
    },
    '.cm-searchMatch.cm-searchMatch-selected': {
      boxShadow: '0px 0px 2px 1px rgba(0, 0, 0, 0.2)',
    },
    '.cm-searchMatch-selected, .cm-searchMatch-selected *': {
      color: '#000000 !important',
      backgroundColor: '#ffff00 !important',
    },
    '.cm-selectionMatch': {
      backgroundColor: colors.selectionHighlight,
    },
    // Control characters
    '.cm-specialChar': {
      color: '#ffffff',
      backgroundColor: '#960000',
    },
    // Extended
    '.cm-visibleTab': {
      backgroundColor: colors.visibleSpace,
    },
    '.cm-visibleSpace::before': {
      color: colors.visibleSpace,
    },
    '.cm-selectedVisible .cm-visibleTab': {
      backgroundColor: `${colors.text}99`,
    },
    '.cm-selectedVisible .cm-visibleSpace::before': {
      color: `${colors.text}99`,
    },
    '.cm-md-inlineCode': {
      backgroundColor: colors.lighterBackground,
    },
    '.cm-md-frontMatter *': {
      color: colors.comment,
    },
    '.cm-md-diff-added': {
      backgroundColor: colors.diffAdded,
    },
    '.cm-md-diff-removed': {
      backgroundColor: colors.diffRemoved,
    },
  };

  const combined = { ...sharedStyles };
  const keys = Object.keys(specs);

  // Create styles by merging two style sheets
  for (const key of keys) {
    const existing = combined[key] as StyleSpec | undefined;
    if (existing !== undefined) {
      combined[key] = { ...existing, ...specs[key] };
    } else {
      combined[key] = specs[key];
    }
  }

  return EditorView.theme(combined, { dark: scheme === 'dark' });
}

function buildHighlight(colors: EditorColors, specs: readonly TagStyle[], scheme?: ColorScheme) {
  const style = HighlightStyle.define([
    ...[
      {
        tag: [
          tags.typeName, tags.attributeName, tags.annotation, tags.namespace, tags.self, tags.changed,
          tags.atom, tags.bool, tags.number,
          tags.contentSeparator, tags.special(tags.variableName),
        ],
        ...shadowableTextColor(colors.accent),
      },
      {
        tag: [
          tags.name, tags.character, tags.labelName,
          tags.separator, tags.processingInstruction, tags.definition(tags.name),
        ],
        ...shadowableTextColor(colors.text),
      },
      { tag: tags.invalid, color: '#ff0000' },
    ],
    ...sharedHighlights, ...specs,
  ], { themeType: scheme });

  return syntaxHighlighting(style);
}

/**
 * Please use box-shadow to create inner borders.
 */
function buildInnerBorder(width: number, color?: string) {
  return color !== undefined ? `inset 0px 0px 0px ${width}px ${color}` : 'none';
}

export { buildTheme, buildHighlight, buildInnerBorder, tags };
