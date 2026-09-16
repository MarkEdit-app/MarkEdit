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

  if (globalState.colors !== undefined) {
    dialog.style.setProperty('--preview-background', globalState.colors.background);
    dialog.style.setProperty('--preview-text', globalState.colors.text);
  }

  const background = window.editor.dom;
  const scaleAnimations: Animation[] = [];
  const animateScale = (element: HTMLElement, from: string, to: string) => {
    scaleAnimations.push(element.animate([
      { scale: from },
      { scale: to },
    ], { duration: 200, easing: 'ease-out', fill: 'forwards' }));
  };

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
      animateScale(background, getComputedStyle(background).scale, '1');
      animateScale(content, getComputedStyle(content).scale, '0.96');

      await dialog.animate([
        { opacity: getComputedStyle(dialog).opacity },
        { opacity: 0 },
      ], { duration: 200, easing: 'ease-out', fill: 'forwards' }).finished.catch(() => {});
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
    scaleAnimations.forEach(animation => animation.cancel());
    frame.dispatchEvent(new Event('preview-close'));
    dialog.remove();
    overlay = undefined;
    window.editor.focus();
  }, { once: true });

  overlay = dialog;
  document.body.appendChild(dialog);
  dialog.showModal();

  if (!isMotionReduced()) {
    animateScale(background, '1', '0.96');
    animateScale(content, '0.96', '1');
  }

  return frame;
}
