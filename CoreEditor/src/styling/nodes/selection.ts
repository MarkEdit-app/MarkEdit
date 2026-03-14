import { Decoration, DecorationSet, EditorView, ViewPlugin, ViewUpdate } from '@codemirror/view';
import { EditorState } from '@codemirror/state';
import { lineDecoRanges } from '../helper';

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
    constructor(editor: EditorView) {
      window.editor = editor;
      this.decorations = createLineDecos(editor.state, className);
    }

    update(update: ViewUpdate) {
      // selectionSet is false when the selected text is cut
      if (!update.selectionSet && !update.docChanged) {
        return;
      }

      this.decorations = createLineDecos(update.state, className);
    }
  }, { decorations: value => value.decorations });
}

function createLineDecos(state: EditorState, className: string) {
  const ranges = state.selection.ranges;
  const lineDecos = ranges.flatMap(range => lineDecoRanges(range.from, range.to, className));
  return Decoration.set(lineDecos.sort((lhs, rhs) => lhs.from - rhs.from));
}
