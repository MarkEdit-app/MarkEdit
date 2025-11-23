import { BlockContext, LeafBlock, MarkdownConfig } from '@lezer/markdown';

/**
 * This extension adds node types to both `[link]:` and `[^id]:` definitions.
 */
export const linkDefinitionConfig: MarkdownConfig = {
  defineNodes: [
    'LinkDefinition',
    'LinkDefinitionID',
    'LinkDefinitionMark',
  ],
  parseBlock: [
    {
      name: 'LinkDefinition',
      leaf(_, leaf) {
        const match = /^\[([^\]]+)\]:/.exec(leaf.content);
        if (match === null) {
          return null;
        }

        const startPos = leaf.start;
        const endPos = startPos + match[0].length - 1; // 1 for ":"
        const finish = (cx: BlockContext, leaf: LeafBlock) => {
          cx.addLeafElement(
            leaf,
            cx.elt(
              'LinkDefinition', startPos, endPos,
              [
                cx.elt('LinkDefinitionMark', startPos, startPos + 1),
                cx.elt('LinkDefinitionID', startPos + 1, endPos - 1),
                cx.elt('LinkDefinitionMark', endPos - 1, endPos),
              ],
            ),
          );

          return true;
        };

        return { finish, nextLine: (cx, _, leaf) => finish(cx, leaf) };
      },
      before: 'LinkReference',
    },
  ],
};
