import { yamlLanguage } from '@codemirror/lang-yaml';
import { parseMixed, SyntaxNodeRef, Input, NestedParse } from '@lezer/common';
import { MarkdownConfig, BlockContext, Line } from '@lezer/markdown';

const frontmatterNodeName = 'Frontmatter';

/**
 * A MarkdownConfig extension that adds YAML frontmatter support as a block
 * within the markdown parser, keeping markdown as the top-level language.
 *
 * This is preferred over yamlFrontmatter() from @codemirror/lang-yaml,
 * which makes the frontmatter parser the top-level language and embeds
 * markdown as a nested parse, inverting the expected language hierarchy.
 */
export const frontmatterMarkdownConfig: MarkdownConfig = {
  defineNodes: [{ name: frontmatterNodeName, block: true }],
  parseBlock: [{
    name: frontmatterNodeName,
    before: 'HorizontalRule',
    parse(cx: BlockContext, line: Line): boolean {
      // Frontmatter must start at the very beginning of the document
      if (cx.lineStart !== 0 || line.text !== '---') {
        return false;
      }

      const start = cx.lineStart;
      cx.nextLine(); // advance past the opening ---

      // Read lines until we find the closing --- or ..., or end of document.
      // Use a type assertion on line.text to satisfy the no-unnecessary-condition
      // lint rule, which sees '---' as the only possible value after the guard above.
      let hasMore = true;
      while (hasMore) {
        const text = line.text as string;
        if (text === '---' || text === '...') {
          cx.nextLine(); // consume the closing marker
          break;
        }
        hasMore = cx.nextLine();
      }

      // Always add an element to ensure all consumed lines appear in the syntax tree.
      cx.addElement(cx.elt(frontmatterNodeName, start, cx.prevLineEnd()));

      return true;
    },
  }],
  wrap: parseMixed((node: SyntaxNodeRef, _input: Input): NestedParse | null => {
    return node.name === frontmatterNodeName ? { parser: yamlLanguage.parser } : null;
  }),
};
