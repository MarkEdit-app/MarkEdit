export interface PinchZoomBridge {
  pinchZoomTarget?: () => PinchZoomTarget | null;
}

export interface PinchZoomTarget {
  scroller: HTMLElement;
  inner: HTMLElement;
}

/**
 * Disable the native magnification (which makes content scrollable), instead
 * using a re-layout strategy that makes the content size fit into the container.
 *
 * Installs `bridge.pinchZoomTarget`, an overridable resolver defaulting to the
 * source editor, and reads it per gesture so extensions can redirect the zoom.
 */
export function enablePinchZoom(bridge: PinchZoomBridge) {
  bridge.pinchZoomTarget = () => {
    const scroller = document.querySelector<HTMLElement>('.cm-scroller');
    const inner = scroller?.querySelector<HTMLElement>('.cm-content') ?? null;
    return scroller !== null && inner !== null ? { scroller, inner } : null;
  };

  let target: PinchZoomTarget | null = null;
  let minValue = MIN_ZOOM_LEVEL;
  let initialValue = 1.0;
  let contentX = 0.0;
  let contentY = 0.0;

  // Resting zoom per element, captured before we ever write an inline zoom.
  const restingZooms = new WeakMap<HTMLElement, number>();
  document.addEventListener('gesturestart', event => {
    target = bridge.pinchZoomTarget?.() ?? null;
    if (target === null) {
      return;
    }

    const gesture = event as GestureEvent;
    gesture.preventDefault();

    const { scroller, inner } = target;
    let resting = restingZooms.get(inner);
    if (resting === undefined) {
      resting = Number(getComputedStyle(inner).zoom) || 1.0;
      restingZooms.set(inner, resting);
    }

    initialValue = Number(inner.style.zoom) || resting;
    minValue = Math.min(MIN_ZOOM_LEVEL, resting);

    const rect = scroller.getBoundingClientRect();
    contentX = (scroller.scrollLeft + gesture.clientX - rect.left) / initialValue;
    contentY = (scroller.scrollTop + gesture.clientY - rect.top) / initialValue;
  }, { passive: false });

  document.addEventListener('gesturechange', event => {
    if (target === null) {
      return;
    }

    const gesture = event as GestureEvent;
    gesture.preventDefault();

    const { scroller, inner } = target;
    const newValue = Math.max(minValue, Math.min(MAX_ZOOM_LEVEL, initialValue * gesture.scale));
    inner.style.zoom = String(newValue);

    const rect = scroller.getBoundingClientRect();
    scroller.scrollLeft = contentX * newValue - (gesture.clientX - rect.left);
    scroller.scrollTop = contentY * newValue - (gesture.clientY - rect.top);
  }, { passive: false });

  document.addEventListener('gestureend', event => {
    if (target === null) {
      return;
    }

    event.preventDefault();
    target = null;
  }, { passive: false });
}

interface GestureEvent extends Event {
  scale: number;
  clientX: number;
  clientY: number;
}

const MIN_ZOOM_LEVEL = 1.0;
const MAX_ZOOM_LEVEL = 2.5;
