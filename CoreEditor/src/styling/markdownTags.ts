import { Tag, tags, styleTags } from '@lezer/highlight';
import type { MarkdownConfig } from '@lezer/markdown';

// Nested Markdown keeps upstream paint tags while gaining semantic classifications
const nestedListMark = Tag.define(tags.processingInstruction);
export const nestedMarkdownTags = {
  InlineCode: Tag.define(tags.monospace),
  CodeInfo: Tag.define(tags.labelName),
  CodeMark: Tag.define(tags.processingInstruction),
  ListMark: nestedListMark,
  TableDelimiter: Tag.define(nestedListMark),
  QuoteMark: Tag.define(tags.processingInstruction),
  LinkMark: Tag.define(tags.processingInstruction),
};

export const nestedMarkdownTagConfig: MarkdownConfig = {
  props: [styleTags(nestedMarkdownTags)],
};
