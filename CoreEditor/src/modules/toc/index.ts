import { KeyBinding } from '@codemirror/view';
import { EditorSelection } from '@codemirror/state';
import { HeadingInfo } from './types';
import { getSyntaxTree } from '../lezer';
import { scrollToSelection } from '../selection';
import { saveGoBackSelection } from '../selection/navigate';
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

  getSyntaxTree(state).iterate({
    from: 0, to: state.doc.length,
    enter: node => {
      // Detect both ATXHeading and SetextHeading
      const match = /^(?:ATX|Setext)Heading(\d)$/.exec(node.name);
      if (match === null) {
        return;
      }

      const title = (() => {
        const isSetext = node.name.startsWith('SetextHeading');
        const text = state.sliceDoc(node.from, node.to);

        if (isSetext) {
          // SetextHeading has a line break
          return text.split(state.lineBreak)[0].trim();
        } else {
          // ATXHeading can have up to 3 leading spaces and arbitrary number of spaces between # and visible characters,
          // example of a valid section header: "   #  Hello"
          return text.replace(/ {0,3}#+ +/, '');
        }
      })();

      results.push({
        title: title.length > 64 ? title.substring(0, 64) + '...' : title,
        level: parseInt(match[1]) as CodeGen_Int,
        from: node.from as CodeGen_Int,
        to: node.to as CodeGen_Int,
        selected: false,
      });
    },
  });

  for (let index = 0; index < results.length; ++index) {
    const item = results[index];
    const next = results[index + 1] as HeadingInfo | undefined;

    // Mark an item as selected if the main selection is between the current item and the next item
    const selection = state.selection.main.head;
    item.selected = selection >= item.from && selection < (next?.from ?? Number.MAX_SAFE_INTEGER);
  }

  return results;
}

export function getLinkAnchor(title: string) {
  return title
    .normalize('NFKD')
    .trim()
    .toLowerCase()
    .replace(/[^\p{Letter}\p{Number}\s\-_]/gu, '')
    .replace(/\s+/g, '-');
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
  saveGoBackSelection();
  selectWithRanges([EditorSelection.cursor(headingInfo.from)]);
  scrollToSelection(window.config.typewriterMode ? 'center' : 'start');
}

export type { HeadingInfo };
