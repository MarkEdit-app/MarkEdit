import { SyntaxNodeRef } from '@lezer/common';
import { parser } from '@lezer/markdown';
import { replaceRange } from '../../common/utils';

export function extractComments(source: string) {
  const tree = parser.parse(source);
  const comments: SyntaxNodeRef[] = [];

  tree.iterate({
    from: 0, to: source.length,
    enter: node => {
      if (node.name === 'Comment' || node.name === 'CommentBlock') {
        comments.push(node.node);
      }
    },
  });

  const result = {
    trimmedText: `${source}`,
    commentCount: comments.length,
  };

  const sorted = comments.sort((lhs, rhs) => rhs.from - lhs.from);
  sorted.forEach(({ from, to }) => {
    result.trimmedText = replaceRange(result.trimmedText, from, to, '');
  });

  return result;
}
