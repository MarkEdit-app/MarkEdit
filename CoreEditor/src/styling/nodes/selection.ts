import { Decoration, DecorationSet, ViewPlugin, ViewUpdate } from '@codemirror/view';

/**
 * CodeMirror only decorates the active line with a cm-activeLine class,
 * we use this extension to decorate all selected ranges.
 *
 * This is useful for implementing features like showing whitespaces for selections.
 */
export const selectedTextDecoration = ViewPlugin.fromClass(class {
  decorations: DecorationSet;
  constructor() {
    this.decorations = Decoration.none;
  }

  update(update: ViewUpdate) {
    if (!update.selectionSet) {
      return;
    }

    const ranges = update.state.selection.ranges.filter(range => range.to !== range.from);
    this.decorations = Decoration.set(ranges.map(range => {
      return Decoration.mark({ class: 'cm-selectedTextRange' }).range(range.from, range.to);
    }));
  }
}, { decorations: instance => instance.decorations });
