import { Decoration, DecorationSet, EditorView, ViewPlugin, ViewUpdate } from '@codemirror/view';
import { lineDecoRanges as createDeco } from '../helper';

/**
 * We only decorate active lines with a cm-md-activeIndicator layer,
 * use this extension to decorate all selected ranges.
 *
 * This is useful for implementing features like showing whitespaces for selections.
 */
export const selectedVisiblesDecoration = createViewPlugin('cm-selectedVisible');

/**
 * We only decorate active lines with a cm-md-activeIndicator layer,
 * use this extension to decorate all selected ranges.
 *
 * This is useful for implementing features like focus mode.
 */
export const selectedLinesDecoration = createViewPlugin('cm-selectedLineRange');

function createViewPlugin(className: string) {
  return ViewPlugin.fromClass(class {
    decorations: DecorationSet;
    constructor(view: EditorView) {
      this.decorations = buildLineDecorations(view.state.selection.ranges, className);
    }

    update(update: ViewUpdate) {
      // selectionSet is false when the selected text is cut
      if (!update.selectionSet && !update.docChanged) {
        return;
      }

      this.decorations = buildLineDecorations(update.state.selection.ranges, className);
    }
  }, { decorations: value => value.decorations });
}

function buildLineDecorations(ranges: readonly { from: number; to: number }[], className: string) {
  const lineDecos = ranges.flatMap(range => createDeco(range.from, range.to, className));
  return Decoration.set(lineDecos.sort((lhs, rhs) => lhs.from - rhs.from));
}
