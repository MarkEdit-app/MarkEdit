import { editingState } from '../../common/store';
import anchorAtPos from '../tokenizer/anchorAtPos';

/**
 * The start of a multi-stage completion process:
 *
 *  1. This method is called automatically if "suggestWhileTyping" is enabled, or manually like pressing cmd-esc on macOS
 *  2. This method calls client with an anchor for tokenization, and optionally the whole document
 *  3. Client determines the "prefix" to complete, and its range
 *  4. Client calls CoreEditor to request the rectangle and shows the panel
 *  5. CoreEditor intercepts navigation keys and calls client to update the panel
 *  6. Client calls CoreEditor to commit the selection
 *
 * Note that, "afterDelay" is used typically for "suggest while typing" scenario.
 */
export function startCompletion({ afterDelay }: { afterDelay: number }) {
  if (storage.cancellable !== undefined) {
    clearTimeout(storage.cancellable);
  }

  // Don't trigger completion for every keystroke,
  // instead we delay the request cancel previously scheduled ones.
  storage.cancellable = setTimeout(() => {
    // We don't want to trigger completion when composition is still ongoing,
    // marked text in input methods like Pinyin is not meaningful until composition is ended.
    if (!editingState.compositionEnded) {
      return;
    }

    const editor = window.editor;
    const state = editor.state;
    const pos = state.selection.main.anchor;

    const fullText = (() => {
      const position = editor.coordsAtPos(pos)?.top ?? 0;
      const usesCache = Math.abs(position - storage.cachedPosition) < 5;
      storage.cachedPosition = position;

      // If y-axis isn't changed noticeably, it means that we are keep working on the same line.
      // In that case, we skip sending full text for tokenization to improve the performance.
      //
      // This is not sound, and we don't want a sound but super complicated algorithm.
      if (usesCache) {
        return undefined;
      } else {
        return state.doc.toString();
      }
    })();

    const anchor = anchorAtPos(pos);
    window.nativeModules.completion.requestCompletions({ anchor, fullText });
  }, afterDelay);
}

export function setPanelVisible(visible: boolean) {
  storage.panelVisible = visible;
}

export function isPanelVisible() {
  return storage.panelVisible;
}

export function invalidateCache() {
  storage.cachedPosition = -1;
}

const storage: {
  cancellable: ReturnType<typeof setTimeout> | undefined;
  cachedPosition: number;
  panelVisible: boolean;
} = {
  cancellable: undefined,
  cachedPosition: -1,
  panelVisible: false,
};
