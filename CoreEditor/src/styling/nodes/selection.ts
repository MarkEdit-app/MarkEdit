import { Decoration, DecorationSet, ViewPlugin, ViewUpdate } from '@codemirror/view';
import { RangeSetBuilder } from '@codemirror/state';
import { linesWithRange } from '../../modules/selection';

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
    if (!selectionHasChanged(update)) {
      return;
    }

    const ranges = update.state.selection.ranges.filter(range => !range.empty);
    const markDeco = Decoration.mark({ class: 'cm-selectedTextRange' });
    this.decorations = Decoration.set(ranges.map(range => {
      return markDeco.range(range.from, range.to);
    }));
  }
}, { decorations: instance => instance.decorations });

/**
 * CodeMirror only decorates the active line with a cm-activeLine class,
 * we use this extension to decorate all selected lines, a line can be partially selected.
 *
 * This is useful for implementing features like focus mode.
 */
export const selectedLinesDecoration = ViewPlugin.fromClass(class {
  decorations: DecorationSet;
  constructor() {
    this.updateDecos();
  }

  update(update: ViewUpdate) {
    if (selectionHasChanged(update)) {
      this.updateDecos();
    }
  }

  updateDecos() {
    const builder = new RangeSetBuilder<Decoration>();
    const ranges = window.editor.state.selection.ranges;
    const lineDeco = Decoration.line({ class: 'cm-selectedLineRange' });

    for (const { from, to } of ranges) {
      for (const line of linesWithRange(from, to)) {
        builder.add(line.from, line.from, lineDeco);
      }
    }

    this.decorations = builder.finish();
  }
}, { decorations: instance => instance.decorations });

function selectionHasChanged(update: ViewUpdate) {
  // selectionSet is false when the selected text is cut
  return update.selectionSet || update.docChanged;
}
