import { Decoration, DecorationSet, ViewPlugin, ViewUpdate } from '@codemirror/view';
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
    constructor() {
      this.decorations = Decoration.none;
    }

    update(update: ViewUpdate) {
      // selectionSet is false when the selected text is cut
      if (!update.selectionSet && !update.docChanged) {
        return;
      }

      const ranges = update.state.selection.ranges;
      const lineDecos = ranges.flatMap(range => createDeco(range.from, range.to, className));
      this.decorations = Decoration.set(lineDecos);
    }
  }, { decorations: value => value.decorations });
}
