import { load as loadYaml } from 'js-yaml';

/**
 * Get the range of possible front matter section.
 */
export function frontMatterRange() {
  const editor = window.editor;
  const state = editor.state;

  // Fail fast, it's not possible to be front matter
  if (state.sliceDoc(0, 3) !== '---') {
    return undefined;
  }

  // Definition: https://jekyllrb.com/docs/front-matter/
  const match = /^---\n(.+?)\n---/s.exec(state.doc.toString());
  if (match && isYaml(match[1])) {
    return { from: 0, to: match[0].length };
  }

  return undefined;
}

function isYaml(source: string) {
  try {
    return typeof loadYaml(source) === 'object';
  } catch (error) {
    return false;
  }
}
