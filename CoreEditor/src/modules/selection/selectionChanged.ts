import { ViewUpdate } from '@codemirror/view';

export default function selectionChanged(update: ViewUpdate) {
  // In CodeMirror, selectionSet can be true even when the new value equals the old one
  return update.selectionSet && !update.startState.selection.eq(update.state.selection);
}
