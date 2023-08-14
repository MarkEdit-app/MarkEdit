import { styleTags } from '@lezer/highlight';
import { MarkdownConfig } from '@lezer/markdown';
import { markdownMathExtension as mathExtension } from '../@vendor/joplin/markdownMathParser';
import { tags } from './builder';
import { contentIndentStyle } from './nodes/indent';
import { inlineCodeStyle, codeBlockStyle, previewMermaid, previewMath } from './nodes/code';
import { linkStyle } from './nodes/link';
import { previewTable, tableStyle } from './nodes/table';
import { frontMatterStyle } from './nodes/frontMatter';

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
 *
 * Order matters, smaller tokens go first.
 */
export const renderExtensions = [
  inlineCodeStyle,
  codeBlockStyle,
  linkStyle,
  contentIndentStyle,
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
];
