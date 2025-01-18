import { forceRedrawElement } from '../../common/utils';

export default function redrawSelectionLayer() {
  const layer = document.querySelector('.cm-selectionLayer') as HTMLElement | null;
  if (layer === null) {
    return;
  }

  forceRedrawElement(layer);
}
