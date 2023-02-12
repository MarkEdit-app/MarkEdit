import { EditorSelection } from '@codemirror/state';
import { syntaxTree } from '@codemirror/language';
import { HeadingInfo } from './types';
import { frontMatterRange } from '../frontMatter';
import { scrollToSelection } from '../selection';
import selectWithRanges from '../selection/selectWithRanges';

export function getTableOfContents() {
  const editor = window.editor;
  const state = editor.state;
  const results: HeadingInfo[] = [];

  // Note that, it's not going to iterate the entire tree (might not have been parsed).
  //
  // This is by design because of potential performance issues.
  syntaxTree(state).iterate({
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
      });
    },
  });

  // Indent each level with 2 spaces, the top level is not indented
  const baseLevel = results.reduce((acc, cur) => Math.min(acc, cur.level), 6);
  results.forEach(item => {
    item.title = `${' '.repeat((item.level - baseLevel) * 2)}${item.title}`;
  });

  return results;
}

export function gotoHeader(headingInfo: HeadingInfo) {
  selectWithRanges([EditorSelection.cursor(headingInfo.from)]);
  scrollToSelection('start');
}

export type { HeadingInfo };
