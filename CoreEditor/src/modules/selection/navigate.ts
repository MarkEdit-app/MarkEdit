import { EditorSelection } from '@codemirror/state';
import { scrollToSelection } from './index';

export function navigateGoBack() {
  if (storage.selectionToGoBack === undefined) {
    return;
  }

  const selection = storage.selectionToGoBack;
  saveGoBackSelection();

  window.editor.dispatch({ selection });
  scrollToSelection();
}

export function saveGoBackSelection() {
  storage.selectionToGoBack = window.editor.state.selection;
}

const storage: {
  selectionToGoBack: EditorSelection | undefined;
} = {
  selectionToGoBack: undefined,
};
