import { KeyBinding } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';
import { ensureSyntaxTree, syntaxTree } from '@codemirror/language';
import { HeadingInfo } from './types';
import { frontMatterRange } from '../frontMatter';
import { scrollToSelection } from '../selection';
import selectWithRanges from '../selection/selectWithRanges';

// Override the system default behavior, it was not necessary until macOS 13.3
export const tocKeymap: KeyBinding[] = [
  {
    key: 'Alt-Mod-ArrowUp',
    preventDefault: true,
    run: () => {
      selectPreviousSection();
      return true;
    },
  },
  {
    key: 'Alt-Mod-ArrowDown',
    preventDefault: true,
    run: () => {
      selectNextSection();
      return true;
    },
  },
];

export function getTableOfContents() {
  const editor = window.editor;
  const state = editor.state;
  const results: HeadingInfo[] = [];

  const tree = (() => {
    const length = state.doc.length;
    // When the doc is small enough (100 KB), we can safely try getting a parse tree
    if (length < 100 * 1024) {
      return ensureSyntaxTree(state, length) ?? syntaxTree(state);
    }

    // Note that, it's not going to iterate the entire tree (might not have been parsed).
    //
    // This is by design because of potential performance issues.
    return syntaxTree(state);
  })();

  tree.iterate({
    from: 0, to: state.doc.length,
    enter: node => {
      // Detect both ATXHeading and SetextHeading
      const match = /^(?:ATX|Setext)Heading(\d)$/.exec(node.name);
      if (match === null) {
        return;
      }

      // If it's inside a front matter section, we will not treat it as a section header
      if (node.name.startsWith('SetextHeading')) {
        const range = frontMatterRange();
        if (range !== undefined && node.from >= range.from && node.to <= range.to) {
          return;
        }
      }

      // ATXHeading can have up to 3 leading spaces and arbitrary number of spaces between # and visible characters,
      // example of a valid section header: "   #  Hello"
      const title = state.doc.sliceString(node.from, node.to).replace(/ {0,3}#+ +/, '');
      const level = parseInt(match[1]);

      results.push({
        title: title.length > 64 ? title.substring(0, 64) + '...' : title,
        level: level as CodeGen_Int,
        from: node.from as CodeGen_Int,
        to: node.to as CodeGen_Int,
        selected: false,
      });
    },
  });

  const baseLevel = results.reduce((acc, cur) => Math.min(acc, cur.level), 6);
  const selection = state.selection.main.head;

  for (let index = 0; index < results.length; ++index) {
    const item = results[index];
    const next = results[index + 1] as HeadingInfo | undefined;

    // Indent each level with 2 spaces, the top level is not indented
    item.title = `${' '.repeat((item.level - baseLevel) * 2)}${item.title}`;

    // Mark an item as selected if the main selection is between the current item and the next item
    item.selected = selection >= item.from && selection < (next?.from ?? Number.MAX_SAFE_INTEGER);
  }

  return results;
}

export function selectPreviousSection() {
  const toc = getTableOfContents();
  const index = Math.max(0, toc.findIndex(info => info.selected) - 1);
  gotoHeader(toc[index]);
}

export function selectNextSection() {
  const toc = getTableOfContents();
  const index = Math.min(toc.length - 1, toc.findIndex(info => info.selected) + 1);
  gotoHeader(toc[index]);
}

export function gotoHeader(headingInfo: HeadingInfo) {
  selectWithRanges([EditorSelection.cursor(headingInfo.from)]);
  scrollToSelection(window.config.typewriterMode ? 'center' : 'start');
}

export type { HeadingInfo };
