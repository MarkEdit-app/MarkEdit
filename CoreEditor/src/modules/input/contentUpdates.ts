import { EditorView, ViewPlugin, ViewUpdate } from '@codemirror/view';
import { completionStatus } from '@codemirror/autocomplete';

export const deferredFormatting = new WeakSet<EditorView>();

export const contentUpdates = ViewPlugin.define(view => {
  let timer: ReturnType<typeof setTimeout> | undefined;
  let contentUpdatePending = false;

  return {
    update(update: ViewUpdate) {
      const retryAfterCompletion = deferredFormatting.has(view)
        && completionStatus(update.startState) !== null
        && completionStatus(update.state) === null;
      if (!update.docChanged && !retryAfterCompletion) {
        return;
      }

      contentUpdatePending ||= update.docChanged;
      clearTimeout(timer);

      timer = setTimeout(() => {
        timer = undefined;
        const retryFormatting = deferredFormatting.has(view) && completionStatus(view.state) === null;
        const shouldNotify = contentUpdatePending || retryFormatting;
        contentUpdatePending = false;

        // Retry through native so formatting, document synchronization, and saving stay together
        if (shouldNotify && window.editor === view) {
          window.nativeModules.core.notifyEditorDidBecomeIdle();
        }
      }, 1500);
    },
    destroy() {
      clearTimeout(timer);
      deferredFormatting.delete(view);
    },
  };
});
