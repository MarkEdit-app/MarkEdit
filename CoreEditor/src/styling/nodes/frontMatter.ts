import { Decoration } from '@codemirror/view';
import { createDecoPlugin } from '../helper';
import { frontMatterRange } from '../../modules/frontMatter';

/**
 * Front Matter: https://jekyllrb.com/docs/front-matter/.
 */
export const frontMatterStyle = createDecoPlugin(() => {
  const range = frontMatterRange();
  if (range === undefined) {
    return Decoration.none;
  }

  // We don't have a cm6 parser for yaml just yet,
  // let's simply decorate the front matter section with a class.
  const deco = Decoration.mark({ class: 'cm-md-frontMatter' }).range(range.from, range.to);
  return Decoration.set(deco);
});
