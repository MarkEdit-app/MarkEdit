import { EditorView } from '@codemirror/view';
import { HighlightStyle, TagStyle, syntaxHighlighting } from '@codemirror/language';
import { Tag, tags as defaultTags } from '@lezer/highlight';
import { StyleSpec } from 'style-mod';
import { ColorScheme, EditorColors } from './types';
import { shadowableTextColor } from './helper';
import { isChrome } from '../common/utils';

// Extend tags by adding Markdown-specific ones
const tags = {
  ...defaultTags,
  inlineCode: Tag.define(),
  codeInfo: Tag.define(),
  codeMark: Tag.define(),
  listMark: Tag.define(),
  quoteMark: Tag.define(),
  linkMark: Tag.define(),
  linkDefinition: Tag.define(),
  setextHeading1: Tag.define(),
  setextHeading2: Tag.define(),
};

// Here we define color independent theme styles,
// it's almost the built-in "baseTheme" concept in CodeMirror but provides more flexibility.
const sharedStyles: { [selector: string]: StyleSpec } = {
  // Default
  '.cm-content': {
    paddingTop: '2px',
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
    // Don't use ui-monospace because ▶︎ and ••• look very big
    fontFamily: 'monospace !important',
    // Make ▼ and ▶︎ more visually centered
    transform: 'translateY(-0.1em)',
  },
  '.cm-foldPlaceholder': {
    margin: '0 4px',
    padding: '0 4px',
    borderRadius: '3px',
    border: 'none',
  },
  '.cm-gutters': {
    borderRight: 'none',
    fontFamily: 'SF Mono, ui-monospace, monospace',
  },
  // '.cm-gutterElement': {
  //   boxShadow: 'inset 0px 0px 0px 1px #f00',
  // },
  '.cm-activeLineGutter': {
    backgroundColor: 'inherit',
  },
  '.cm-snippetFieldPosition': {
    borderLeft: 'none',
  },
  '.cm-tooltip-autocomplete': {
    overflow: 'auto',
    marginTop: '5px',
    borderRadius: '5px',
    maxWidth: '1280px',
  },
  '.cm-tooltip-autocomplete ul': {
    maxHeight: 'var(--tooltip-completion-max-height) !important',
  },
  '.cm-tooltip-autocomplete ul li': {
    padding: '4px !important',
    lineHeight: '1.2 !important',
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
  '.cm-visibleSpace::before, .cm-visibleLineBreak::before': {
    content: 'attr(content)',
    position: 'absolute',
    pointerEvents: 'none',
  },
  '.cm-md-monospace, .cm-md-monospace *, .cm-md-codeBlock *, .cm-md-table *': {
    fontFamily: 'SF Mono, ui-monospace, monospace',
  },
  '.cm-md-inlineCode': {
    borderRadius: '3px',
  },
};

// Here we define color independent highlight styles
const sharedHighlights = [
  { tag: tags.strong, fontWeight: 'bolder' },
  { tag: [tags.emphasis, tags.quote], fontStyle: 'italic' },
  { tag: tags.strikethrough, textDecoration: 'line-through' },
  { tag: tags.link, textDecoration: 'underline' },
  { tag: tags.monospace, fontFamily: 'SF Mono, ui-monospace, monospace' },
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
    // Autocomplete
    '.cm-tooltip-autocomplete': {
      border: `1px solid ${colors.text}4d`,
      backgroundColor: `${colors.background}99`,
      backdropFilter: 'blur(10px)',
      boxShadow: '0 2px 6px rgba(0, 0, 0, 0.12), 0 4px 12px rgba(0, 0, 0, 0.08)',
    },
    '.cm-tooltip-autocomplete ul li[aria-selected]': {
      backgroundColor: `${colors.text}12`,
    },
    '.cm-tooltip-autocomplete ul li, .cm-tooltip-autocomplete ul li[aria-selected]': {
      color: colors.text,
    },
    '.cm-completionMatchedText': {
      fontWeight: '500',
      textDecoration: 'none',
      ...shadowableTextColor(colors.accent),
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
    '.cm-visibleSpace::before, .cm-visibleLineBreak::before': {
      color: colors.visibleSpace,
    },
    '.cm-selectedVisible .cm-visibleTab': {
      backgroundColor: `${colors.text}99`,
    },
    '.cm-selectedVisible .cm-visibleSpace::before, .cm-selectedVisible .cm-visibleLineBreak::before': {
      color: `${colors.text}99`,
    },
    '.cm-md-activeIndicator': {
      background: colors.activeLine,
      boxShadow: buildInnerBorder(2.5, colors.lineBorder),
    },
    '.cm-md-inlineCode': {
      backgroundColor: colors.lighterBackground,
    },
    '.cm-md-previewButton': {
      backgroundImage: (() => {
        const strokeColor = `%23${colors.comment.substring(1)}`; // %23 -> #
        const strokeWidth = '1.5';
        return `url('data:image/svg+xml,<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg"><path d="M2.42012 12.7132C2.28394 12.4975 2.21584 12.3897 2.17772 12.2234C2.14909 12.0985 2.14909 11.9015 2.17772 11.7766C2.21584 11.6103 2.28394 11.5025 2.42012 11.2868C3.54553 9.50484 6.8954 5 12.0004 5C17.1054 5 20.4553 9.50484 21.5807 11.2868C21.7169 11.5025 21.785 11.6103 21.8231 11.7766C21.8517 11.9015 21.8517 12.0985 21.8231 12.2234C21.785 12.3897 21.7169 12.4975 21.5807 12.7132C20.4553 14.4952 17.1054 19 12.0004 19C6.8954 19 3.54553 14.4952 2.42012 12.7132Z" stroke="${strokeColor}" stroke-width="${strokeWidth}"/><path d="M12.0004 15C13.6573 15 15.0004 13.6569 15.0004 12C15.0004 10.3431 13.6573 9 12.0004 9C10.3435 9 9.0004 10.3431 9.0004 12C9.0004 13.6569 10.3435 15 12.0004 15Z" stroke="${strokeColor}" stroke-width="${strokeWidth}"/></svg>')`;
      })(),
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
