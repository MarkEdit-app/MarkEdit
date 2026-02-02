import { Decoration } from '@codemirror/view';
import { Range, RangeValue } from '@codemirror/state';
import { syntaxTree } from '@codemirror/language';
import { SyntaxNodeRef } from '@lezer/common';
import { WidgetView } from '../views/types';
import { lineDecoRanges } from '../helper';

/**
 * Create mark decorations.
 *
 * @param nodeName Node name(s), such as "ATXHeading1" for headings
 * @param className Class to decorate the node
 */
export function createMarkDeco(nodeName: string | string[], className: string) {
  return createDecos(nodeName, node => {
    return Decoration.mark({ class: className }).range(node.from, node.to);
  });
}

/**
 * Create widget decorations.
 *
 * @param nodeName Node name(s), such as "ATXHeading1" for headings
 * @param builder Closure to create a widget decoration
 */
export function createWidgetDeco(nodeName: string | string[], builder: (node: SyntaxNodeRef) => WidgetView | null) {
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
 * Create line decorations.
 *
 * @param nodeName Node name(s), such as "FencedCode" for ``` code blocks
 * @param className Class to decorate the node
 */
export function createLineDeco(nodeName: string | string[], className: string, attributes?: { [key: string]: string }) {
  return createDecos(nodeName, node => lineDecoRanges(node.from, node.to, className, attributes));
}

/**
 * Build decorations by leveraging language lexers.
 *
 * https://github.com/lezer-parser/markdown/blob/main/src/markdown.ts
 *
 * @param nodeName Node name(s), such as "ATXHeading1" for headings
 * @param builder Closure to create the Decoration(s)
 */
export function createDecos(nodeName: string | string[], builder: (node: SyntaxNodeRef) => Range<Decoration> | Range<Decoration>[] | null) {
  return Decoration.set(createNodeRanges(nodeName, builder));
}

/**
 * Build generic node ranges by leveraging language lexers.
 *
 * @param nodeName Node name(s), such as "ATXHeading1" for headings
 * @param builder Closure to create the range(s)
 */
function createNodeRanges<T extends RangeValue>(nodeName: string | string[], builder: (node: SyntaxNodeRef) => Range<T> | Range<T>[] | null) {
  const editor = window.editor;
  const ranges: Range<T>[] = [];
  const nodeNames = Array.isArray(nodeName) ? nodeName : [nodeName];

  for (const { from, to } of editor.visibleRanges) {
    syntaxTree(editor.state).iterate({
      from, to,
      enter: node => {
        if (nodeNames.includes(node.name)) {
          const range = builder(node) ?? [];
          ranges.push(...Array.isArray(range) ? range : [range]);
        }
      },
    });
  }

  return ranges.sort((lhs, rhs) => lhs.from - rhs.from);
}
