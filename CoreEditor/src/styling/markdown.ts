import { syntaxHighlighting } from '@codemirror/language';
import { classHighlighter, tagHighlighter, styleTags } from '@lezer/highlight';
import { MarkdownConfig } from '@lezer/markdown';
import { markdownMathExtension as mathExtension } from '../@vendor/joplin/markdownMathParser';
import { tags } from './builder';
import { listIndentStyle } from './nodes/indent';
import { inlineCodeStyle, codeBlockStyle, previewMermaid, previewMath } from './nodes/code';
import { previewTable, tableStyle } from './nodes/table';
import { frontMatterStyle } from './nodes/frontMatter';
import { taskMarkerStyle } from './nodes/task';

export const classHighlighters = [
  syntaxHighlighting(classHighlighter),
  syntaxHighlighting(tagHighlighter([
    { tag: tags.heading1, class: 'cm-md-header cm-md-heading1' },
    { tag: tags.heading2, class: 'cm-md-header cm-md-heading2' },
    { tag: tags.heading3, class: 'cm-md-header cm-md-heading3' },
    { tag: tags.heading4, class: 'cm-md-header cm-md-heading4' },
    { tag: tags.heading5, class: 'cm-md-header cm-md-heading5' },
    { tag: tags.heading6, class: 'cm-md-header cm-md-heading6' },
    { tag: tags.setextHeading1, class: 'cm-md-header cm-md-heading1 cm-md-setext-heading1' },
    { tag: tags.setextHeading2, class: 'cm-md-header cm-md-heading2 cm-md-setext-heading2' },
    { tag: tags.strong, class: 'cm-md-bold' },
    { tag: tags.emphasis, class: 'cm-md-italic' },
    { tag: tags.strikethrough, class: 'cm-md-strikethrough' },
    { tag: tags.url, class: 'cm-md-url' },
    { tag: tags.codeInfo, class: 'cm-md-codeInfo' },
    { tag: tags.codeMark, class: 'cm-md-codeMark' },
    { tag: tags.linkMark, class: 'cm-md-linkMark' },
    { tag: tags.listMark, class: 'cm-md-listMark' },
    { tag: tags.quote, class: 'cm-md-quote' },
    { tag: tags.quoteMark, class: 'cm-md-quoteMark' },
    { tag: tags.contentSeparator, class: 'cm-md-horizontalRule' },
  ])),
];

// https://github.com/lezer-parser/markdown/blob/main/src/markdown.ts
export const markdownExtensions: MarkdownConfig[] = [
  {
    props: [
      styleTags({
        InlineCode: tags.inlineCode,
        CodeInfo: tags.codeInfo,
        CodeMark: tags.codeMark,
        ListMark: tags.listMark,
        QuoteMark: tags.quoteMark,
        LinkMark: tags.linkMark,
        'SetextHeading1/...': tags.setextHeading1,
        'SetextHeading2/...': tags.setextHeading2,
      }),
    ],
  },
  mathExtension,
];

// https://codemirror.net/docs/ref/#state.EditorState.languageDataAt
export const markdownExtendedData = {
  closeBrackets: {
    brackets: [
      // Default
      '(', '[', '{', '\'', '"',
      // Custom
      '`',
    ],
  },
};

/**
 * Extensions used in all scenarios.
 *
 * Order matters, smaller tokens go first.
 */
export const renderExtensions = [
  inlineCodeStyle,
  codeBlockStyle,
  listIndentStyle,
  tableStyle,
  frontMatterStyle,
];

/**
 * Extensions used only in the full editor, i.e., the preview extension doesn't use these.
 */
export const actionExtensions = [
  previewMermaid,
  previewMath,
  previewTable,
  taskMarkerStyle,
];
