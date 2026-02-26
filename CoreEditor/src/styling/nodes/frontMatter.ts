import { createBlockPlugin, createDecoPlugin } from '../helper';
import { createBlockWrappers, createLineDeco } from '../matchers/lezer';

// NOT "FrontMatter"
const nodeName = 'Frontmatter';

/**
 * Front Matter: https://jekyllrb.com/docs/front-matter/.
 */
export const frontMatterStyle = [
  createBlockPlugin(() => createBlockWrappers(nodeName, 'cm-md-frontMatterWrapper')),
  createDecoPlugin(() => createLineDeco(nodeName, 'cm-md-frontMatter')),
];
