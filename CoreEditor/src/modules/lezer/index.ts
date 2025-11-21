import { EditorState } from '@codemirror/state';
import { ensureSyntaxTree, syntaxTree } from '@codemirror/language';
import { SyntaxNodeRef } from '@lezer/common';
import { parser as htmlParser } from '@lezer/html';
import { parser as markdownParser } from '@lezer/markdown';
import { replaceRange } from '../../common/utils';
import { takePossibleNewline } from '../lineEndings';

export function getSyntaxTree(state: EditorState, sizeLimit = 102400) {
  const length = state.doc.length;
  // When the doc is small enough (default 100 KB), we can safely try getting a parse tree
  if (length < sizeLimit) {
    return ensureSyntaxTree(state, length) ?? syntaxTree(state);
  }

  // Note that, it's not going to iterate the entire tree (might not have been parsed).
  //
  // This is by design because of potential performance issues.
  return syntaxTree(state);
}

export function getNodesNamed(state: EditorState, nodeNames: string[]) {
  const nodes: SyntaxNodeRef[] = [];

  getSyntaxTree(state).iterate({
    from: 0, to: state.doc.length,
    enter: node => {
      if (nodeNames.includes(node.name)) {
        nodes.push(node.node);
      }
    },
  });

  return nodes;
}

export function getReadableContent(source: string) {
  const result = {
    trimmedText: `${source}`,
    paragraphCount: 0,
    commentCount: 0,
  };

  // Parse the content as syntax tree
  const tree = markdownParser.parse(source);
  const comments: { from: number; to: number }[] = [];

  tree.iterate({
    from: 0, to: source.length,
    enter: node => {
      // Get number of paragraphs
      if (node.name === 'Paragraph') {
        result.paragraphCount += 1;
      }

      // Get comment ranges
      if (node.name === 'Comment' || node.name === 'CommentBlock') {
        const offset = node.from;
        const html = source.slice(offset, node.to);

        // A "CommentBlock" in Markdown can be something like this:
        //   <!-- Hello --> World
        //
        // The Markdown parser won't extract the "comment" part,
        // here we need to parse it again using a html parser.
        htmlParser.parse(html).iterate({
          from: 0, to: html.length,
          enter: comment => {
            if (comment.name !== 'Comment') {
              return;
            }

            // Text range with offset from the original Markdown source
            comments.push({
              from: comment.from + offset,
              to: comment.to + offset,
            });
          },
        });
      }
    },
  });

  // Reversely remove all comments from the source text
  const sorted = comments.sort((lhs, rhs) => rhs.from - lhs.from);
  sorted.forEach(({ from, to }) => {
    result.trimmedText = replaceRange(result.trimmedText, from, takePossibleNewline(result.trimmedText, to), '');
  });

  result.commentCount = comments.length;
  return result;
}
