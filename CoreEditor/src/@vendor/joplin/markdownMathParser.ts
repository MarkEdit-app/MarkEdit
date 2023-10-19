// Thanks to https://github.com/laurent22/joplin/blob/dev/packages/editor/CodeMirror/markdown/markdownMathParser.ts

import { tags, Tag } from "@lezer/highlight";
import { parseMixed, SyntaxNodeRef, Input, NestedParse, ParseWrapper } from "@lezer/common";

// Extend the existing markdown parser
import { MarkdownConfig, BlockContext, Line, LeafBlock } from "@lezer/markdown";

// The existing stexMath parser is used to parse the text between the $s
import { stexMath } from "@codemirror/legacy-modes/mode/stex";
import { StreamLanguage } from "@codemirror/language";

// (?:[>]\s*)?: Optionally allow block math lines to start with '> '
const mathBlockStartRegex = /^(?:\s*[>]\s*)?\$\$/;
const mathBlockEndRegex = /\$\$\s*$/;

const texLanguage = StreamLanguage.define(stexMath);
export const blockMathTagName = "BlockMath";
export const blockMathContentTagName = "BlockMathContent";
export const inlineMathTagName = "InlineMath";
export const inlineMathContentTagName = "InlineMathContent";

export const mathTag = Tag.define(tags.monospace);
export const inlineMathTag = Tag.define(mathTag);

/**
 * Wraps a TeX math-mode parser. This removes [nodeTag] from the syntax tree
 * and replaces it with a region handled by the sTeXMath parser.
 *
 * @param nodeTag Name of the nodes to replace with regions parsed by the sTeX parser.
 * @returns a wrapped sTeX parser.
 */
const wrappedTeXParser = (nodeTag: string): ParseWrapper => {
  return parseMixed((node: SyntaxNodeRef, _input: Input): NestedParse | null => {
    if (node.name !== nodeTag) {
      return null;
    }

    return {
      parser: texLanguage.parser,
    };
  });
};

// Extension for recognising block code
const BlockMathConfig: MarkdownConfig = {
  defineNodes: [
    {
      name: blockMathTagName,
      style: mathTag,
    },
    {
      name: blockMathContentTagName,
    },
  ],
  parseBlock: [
    {
      name: blockMathTagName,
      before: "Blockquote",
      parse(cx: BlockContext, line: Line): boolean {
        const delimLen = 2;

        // $$ delimiter? Start math!
        const mathStartMatch = mathBlockStartRegex.exec(line.text);
        if (mathStartMatch) {
          const start = cx.lineStart + mathStartMatch[0].length;
          let stop;

          let endMatch = mathBlockEndRegex.exec(line.text.substring(mathStartMatch[0].length));

          // If the math region ends immediately (on the same line),
          if (endMatch) {
            const lineLength = line.text.length;
            stop = cx.lineStart + lineLength - endMatch[0].length;
          } else {
            let hadNextLine = false;

            // Otherwise, it's a multi-line block display.
            // Consume lines until we reach the end.
            do {
              hadNextLine = cx.nextLine();
              endMatch = hadNextLine ? mathBlockEndRegex.exec(line.text) : null;
            } while (hadNextLine && endMatch === null);

            if (hadNextLine && endMatch) {
              const lineLength = line.text.length;

              // Remove the ending delimiter
              stop = cx.lineStart + lineLength - endMatch[0].length;
            } else {
              stop = cx.lineStart;
            }
          }
          const lineEnd = cx.lineStart + line.text.length;

          // Label the region. Add two labels so that one can be removed.
          const contentElem = cx.elt(blockMathContentTagName, start, stop);
          const containerElement = cx.elt(
            blockMathTagName,
            start - delimLen,

            // Math blocks don't need ending delimiters, so ensure we don't
            // include text that doesn't exist.
            Math.min(lineEnd, stop + delimLen),

            // The child of the container element should be the content element
            [contentElem]
          );
          cx.addElement(containerElement);

          // Don't re-process the ending delimiter (it may look the same
          // as the starting delimiter).
          cx.nextLine();

          return true;
        }

        return false;
      },
      // End paragraph-like blocks
      endLeaf(_cx: BlockContext, line: Line, _leaf: LeafBlock): boolean {
        // Leaf blocks (e.g. block quotes) end early if math starts.
        return mathBlockStartRegex.exec(line.text) !== null;
      },
    },
  ],
  wrap: wrappedTeXParser(blockMathContentTagName),
};

/** Markdown configuration for block math support. */
export const markdownMathExtension = BlockMathConfig;
