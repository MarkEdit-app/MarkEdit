import { isMotionReduced } from '../../common/utils';
import { globalState } from '../../common/store';
import type { PreviewType } from './index';

let overlay: HTMLDialogElement | undefined;

export default function createPreviewOverlay(type: PreviewType): HTMLIFrameElement | undefined {
  if (overlay !== undefined) {
    return;
  }

  const dialog = document.createElement('dialog');
  dialog.className = 'cm-previewOverlay';

  const updateColors = () => {
    if (globalState.colors !== undefined) {
      dialog.style.setProperty('--preview-background', globalState.colors.background);
      dialog.style.setProperty('--preview-text', globalState.colors.text);
    }
  };

  updateColors();
  window.addEventListener('editor-colors-changed', updateColors);

  dialog.setAttribute('aria-label', window.config.localizable?.previewButtonTitle ?? 'Preview');
  dialog.addEventListener('keydown', event => {
    if (event.key === 'Tab') {
      dialog.classList.add('cm-previewKeyboardFocus');
    }
  });

  let isDismissing = false;
  const dismissPreview = async () => {
    if (isDismissing) {
      return;
    }

    isDismissing = true;
    if (!isMotionReduced()) {
      await dialog.animate([
        { opacity: getComputedStyle(dialog).opacity },
        { opacity: 0 },
      ], { duration: 160, easing: 'ease-out', fill: 'forwards' }).finished.catch(() => {});
    }

    if (dialog.open) {
      dialog.close();
    }
  };

  dialog.addEventListener('cancel', event => {
    event.preventDefault();
    void dismissPreview();
  });

  const closeButton = dialog.appendChild(document.createElement('button'));
  closeButton.className = 'cm-previewClose';
  closeButton.type = 'button';
  closeButton.autofocus = true;
  closeButton.title = window.config.localizable?.closeButtonTitle ?? 'Close';
  closeButton.setAttribute('aria-label', closeButton.title);
  closeButton.addEventListener('click', () => void dismissPreview());

  const scroller = dialog.appendChild(document.createElement('div'));
  scroller.className = 'cm-previewScroller';

  const content = scroller.appendChild(document.createElement('div'));
  content.className = `cm-previewContent cm-preview-${type}`;

  const frame = content.appendChild(document.createElement('iframe'));
  frame.className = 'cm-previewFrame';
  frame.title = window.config.localizable?.previewButtonTitle ?? 'Preview';
  frame.setAttribute('sandbox', 'allow-scripts');

  dialog.addEventListener('close', () => {
    window.removeEventListener('editor-colors-changed', updateColors);
    frame.dispatchEvent(new Event('preview-close'));
    dialog.remove();
    overlay = undefined;
    window.editor.focus();
  }, { once: true });

  overlay = dialog;
  document.body.appendChild(dialog);
  dialog.showModal();

  return frame;
}
