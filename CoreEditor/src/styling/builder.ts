import { EditorView } from '@codemirror/view';
import { HighlightStyle, TagStyle, syntaxHighlighting } from '@codemirror/language';
import { Tag, tags as defaultTags } from '@lezer/highlight';
import { StyleSpec } from 'style-mod';
import { ColorScheme, BaseColors, EditorColors } from './types';
import { shadowableTextColor } from './helper';

// Extend tags by adding Markdown-specific ones
const tags = {
  ...defaultTags,
  inlineCode: Tag.define(),
  codeInfo: Tag.define(),
  codeMark: Tag.define(),
  listMark: Tag.define(),
  quoteMark: Tag.define(),
  linkMark: Tag.define(),
};

// Here we define color independent theme styles,
// it's almost the built-in "baseTheme" concept in CodeMirror but provides more flexibility.
const sharedStyles: { [selector: string]: StyleSpec } = {
  // Default
  '.cm-content': {
    paddingRight: '12px',
    paddingBottom: '50vh',
  },
  '.cm-cursor': {
    borderLeftWidth: '2px',
  },
  '.cm-focused': {
    outline: 'none',
  },
  '.cm-foldGutter': {
    padding: '0 4px',
    opacity: '0',
    transition: '0.4s',
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
  '.cm-gutters:hover .cm-foldGutter:not(:hover), .cm-foldGutter:hover': {
    opacity: '1',
  },
  '.cm-activeLineGutter': {
    backgroundColor: 'inherit',
  },
  '.cm-snippetFieldPosition': {
    borderLeft: 'none',
  },
  // Extended
  '.cm-visibleTab': {
    backgroundImage: 'url(\'data:image/svg+xml,<svg xmlns="http://www.w3.org/2000/svg" width="200" height="20"><path stroke="%23888" stroke-width="1.2" fill="none" stroke-linecap="round" stroke-linejoin="round" d="M190.5 5l6 5m-6 5l6-5M1 10h195"/></svg>\')',
    backgroundSize: 'auto 100%',
    backgroundPosition: 'right 90%',
    backgroundRepeat: 'no-repeat',
  },
  '.cm-visibleSpace:before': {
    content: 'attr(content)',
    position: 'absolute',
    pointerEvents: 'none',
  },
  '.cm-md-monospace, .cm-md-fencedCode *, .cm-md-table *': {
    fontFamily: 'ui-monospace, monospace',
  },
};

// Here we define color independent highlight styles
const sharedHighlights = [
  // Basic
  { tag: tags.strong, fontWeight: 'bold' },
  { tag: [tags.emphasis, tags.quote], fontStyle: 'italic' },
  { tag: tags.strikethrough, textDecoration: 'line-through' },
  { tag: tags.link, textDecoration: 'underline' },
  { tag: tags.monospace, fontFamily: 'ui-monospace, monospace' },

  // Markdown
  { tag: tags.heading1, class: 'cm-md-header cm-md-heading1' },
  { tag: tags.heading2, class: 'cm-md-header cm-md-heading2' },
  { tag: tags.heading3, class: 'cm-md-header cm-md-heading3' },
  { tag: tags.heading4, class: 'cm-md-header cm-md-heading4' },
  { tag: tags.heading5, class: 'cm-md-header cm-md-heading5' },
  { tag: tags.heading6, class: 'cm-md-header cm-md-heading6' },
];

function buildTheme(colors: EditorColors, scheme?: ColorScheme) {
  const specs = {
    // Root
    '&': {
      color: colors.text,
      backgroundColor: colors.background,
    },
    // Caret
    '.cm-content': {
      caretColor: colors.caret,
    },
    '.cm-cursor, .cm-dropCursor': {
      borderLeftColor: colors.caret,
    },
    // Selection
    '&.cm-focused .cm-selectionBackground, .cm-selectionBackground, .cm-content ::selection': {
      backgroundColor: colors.selection,
    },
    '.cm-activeLine': {
      backgroundColor: colors.activeLine,
      boxShadow: innerBorder(2.5, colors.lineBorder),
    },
    // Brackets
    '&.cm-focused .cm-matchingBracket, &.cm-focused .cm-nonmatchingBracket': {
      backgroundColor: colors.matchingBracket,
      boxShadow: innerBorder(1.5, colors.bracketBorder),
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
      backgroundColor: colors.selectedMatch,
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
    '.cm-visibleSpace:before': {
      color: colors.visibleSpace,
    },
    '.cm-md-inlineCode': {
      backgroundColor: colors.lighterBackground,
    },
    '.cm-md-frontMatter *': {
      color: colors.comment,
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

function buildHighlight(colors: BaseColors, specs: readonly TagStyle[], scheme?: ColorScheme) {
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
function innerBorder(width: number, color?: string) {
  return color !== undefined ? `inset 0px 0px 0px ${width}px ${color}` : 'none';
}

export { buildTheme, buildHighlight, tags };
