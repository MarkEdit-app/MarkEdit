import { createBlockPlugin, createDecoPlugin } from '../helper';
import { createBlockWrappers, createLineDeco } from '../matchers/lezer';

/**
 * Front Matter: https://jekyllrb.com/docs/front-matter/.
 */
export const frontMatterStyle = [
  createBlockPlugin(() => createBlockWrappers('Frontmatter', 'cm-md-frontMatterWrapper')),
  createDecoPlugin(() => createLineDeco('Frontmatter', 'cm-md-frontMatter')),
];
