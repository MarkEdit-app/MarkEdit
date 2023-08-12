import { Decoration } from '@codemirror/view';
import { Range } from '@codemirror/state';
import { syntaxTree } from '@codemirror/language';
import { SyntaxNodeRef } from '@lezer/common';
import { WidgetView } from '../../views/types';

/**
 * Create mark decorations.
 *
 * @param nodeName Node name, such as "ATXHeading1" for headings
 * @param className Class to decorate the node
 */
export function createMarkDeco(nodeName: string, className: string) {
  return createDecos(nodeName, node => {
    return Decoration.mark({ class: className }).range(node.from, node.to);
  });
}

/**
 * Create widget decorations.
 *
 * @param nodeName Node name, such as "ATXHeading1" for headings
 * @param builder Closure to create a widget decoration
 */
export function createWidgetDeco(nodeName: string, builder: (node: SyntaxNodeRef) => WidgetView | null) {
  return createDecos(nodeName, node => {
    const widget = builder(node);
    if (widget === null) {
      return null;
    } else {
      return Decoration.widget({ widget, side: 1 }).range(widget.pos);
    }
  });
}

/**
 * Build decorations by leveraging language lexers.
 *
 * https://github.com/lezer-parser/markdown/blob/main/src/markdown.ts
 *
 * @param nodeName Node name, such as "ATXHeading1" for headings
 * @param builder Closure to create the Decoration
 */
export function createDecos(nodeName: string, builder: (node: SyntaxNodeRef) => Range<Decoration> | null) {
  const editor = window.editor;
  const ranges: Range<Decoration>[] = [];

  for (const { from, to } of editor.visibleRanges) {
    syntaxTree(editor.state).iterate({
      from, to,
      enter: node => {
        if (node.name === nodeName) {
          const range = builder(node);
          if (range) {
            ranges.push(range);
          }
        }
      },
    });
  }

  return Decoration.set(ranges);
}
