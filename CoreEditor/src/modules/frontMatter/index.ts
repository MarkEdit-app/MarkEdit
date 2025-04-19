import { load as loadYaml } from 'js-yaml';
import { replaceRange } from '../../common/utils';

/**
 * Get the range of possible front matter section.
 */
export function frontMatterRange(source?: string) {
  const editor = window.editor;
  const state = editor.state;
  const header = source === undefined ? state.sliceDoc(0, 3) : source.substring(0, 3);

  // Fail fast, it's not possible to be front matter
  if (header !== '---') {
    return undefined;
  }

  // Definition: https://jekyllrb.com/docs/front-matter/
  const text = source === undefined ? state.doc.toString() : source;
  const match = /^---\n(.+?)\n---/s.exec(text);
  if (match && isYaml(match[1])) {
    return { from: 0, to: match[0].length };
  }

  return undefined;
}

export function removeFrontMatter(source: string) {
  const range = frontMatterRange(source);
  if (range === undefined) {
    return source;
  }

  return replaceRange(source, range.from, range.to, '');
}

function isYaml(source: string) {
  try {
    return typeof loadYaml(source) === 'object';
  } catch (error) {
    return false;
  }
}
