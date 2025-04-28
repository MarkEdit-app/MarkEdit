import { parser as htmlParser } from '@lezer/html';
import { parser as markdownParser } from '@lezer/markdown';
import { replaceRange } from '../../common/utils';
import { takePossibleNewline } from '../lineEndings';

export function extractComments(source: string) {
  // Fail fast since we cannot find an open tag of comments
  if (!source.includes('<!--')) {
    return {
      trimmedText: source,
      commentCount: 0,
    };
  }

  // Parse the content as syntax tree, time-consuming for long content
  const tree = markdownParser.parse(source);
  const comments: { from: number; to: number }[] = [];

  tree.iterate({
    from: 0, to: source.length,
    enter: node => {
      if (node.name !== 'Comment' && node.name !== 'CommentBlock') {
        return;
      }

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
    },
  });

  const result = {
    trimmedText: `${source}`,
    commentCount: comments.length,
  };

  // Enumerate reversely
  const sorted = comments.sort((lhs, rhs) => rhs.from - lhs.from);
  sorted.forEach(({ from, to }) => {
    result.trimmedText = replaceRange(result.trimmedText, from, takePossibleNewline(result.trimmedText, to), '');
  });

  return result;
}
