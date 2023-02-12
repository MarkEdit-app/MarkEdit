import { Decoration } from '@codemirror/view';
import { createDecoPlugin } from '../helper';
import { load as loadYaml } from 'js-yaml';

/**
 * Front Matter: https://jekyllrb.com/docs/front-matter/.
 */
export const frontMatterStyle = createDecoPlugin(() => {
  const editor = window.editor;
  const doc = editor.state.doc;

  // Fail fast, it's not possible to be front matter
  if (doc.sliceString(0, 3) !== '---') {
    return Decoration.none;
  }

  // We don't have a cm6 parser for yaml just yet,
  // let's simply decorate the front matter section with a class.
  const match = /^---\n(.+?)\n---/s.exec(doc.toString());
  if (match && isYaml(match[1])) {
    const deco = Decoration.mark({ class: 'cm-md-frontMatter' }).range(0, match[0].length);
    return Decoration.set(deco);
  }

  return Decoration.none;
});

function isYaml(source: string) {
  try {
    return typeof loadYaml(source) === 'object';
  } catch (error) {
    return false;
  }
}
