import { styleTags } from '@lezer/highlight';
import { MarkdownConfig } from '@lezer/markdown';
import { markdownMathExtension as mathExtension } from '../@vendor/joplin/markdownMathParser';
import { tags } from './builder';
import { inlineCodeStyle, fencedCodeStyle, previewMermaid, previewMath } from './nodes/code';
import { previewTable, tableStyle } from './nodes/table';

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
      }),
    ],
  },
  mathExtension,
];

/**
 * Extensions used in all scenarios.
 */
export const renderExtensions = [
  inlineCodeStyle,
  fencedCodeStyle,
  tableStyle,
];

/**
 * Extensions used only in the full editor, i.e., the preview extension doesn't use these.
 */
export const actionExtensions = [
  previewMermaid,
  previewMath,
  previewTable,
];
