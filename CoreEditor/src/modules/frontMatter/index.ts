import { yamlFrontmatter as frontMatter } from '@codemirror/lang-yaml';
import { markdown } from '../../@vendor/lang-markdown';
import { replaceRange } from '../../common/utils';
import { takePossibleNewline } from '../lineEndings';

const config = { content: markdown() };
const parser = frontMatter(config).language.parser;

/**
 * Get the range of possible front matter section.
 */
export function frontMatterRange(source?: string) {
  const editor = window.editor;
  const state = editor.state;
  const leadingMarks = source === undefined ? state.sliceDoc(0, 3) : source.substring(0, 3);

  // Fail fast, it's not possible to be front matter
  if (leadingMarks !== '---') {
    return undefined;
  }

  // Definition: https://jekyllrb.com/docs/front-matter/
  const text = source === undefined ? state.doc.toString() : source;
  if (!/^---[ \t]*\r?\n[\s\S]*?\n---[ \t]*(?:\r?\n|$)/.test(text)) {
    return undefined;
  }

  const result = { from: -1, to: -1 };
  parser.parse(text).iterate({
    enter: node => {
      if (node.name === 'Frontmatter' && result.from < 0) {
        result.from = node.from;
        result.to = node.to;
      }
    },
  });

  return result.from < 0 ? undefined : result;
}

export function removeFrontMatter(source: string) {
  const range = frontMatterRange(source);
  if (range === undefined) {
    return source;
  }

  return replaceRange(source, range.from, takePossibleNewline(source, range.to), '');
}
