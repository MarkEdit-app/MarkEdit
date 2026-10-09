import { afterEach, beforeEach, describe, expect, jest, test } from '@jest/globals';
import { enableDragGestures } from '../src/@quicklook';

jest.mock('../src/@quicklook/zoom', () => ({
  enablePinchZoom: jest.fn(),
}));

describe('Quick Look scrollbar gestures', () => {
  let scroller: HTMLDivElement;

  beforeEach(() => {
    scroller = document.createElement('div');
    scroller.className = 'cm-scroller';
    Object.defineProperties(scroller, {
      clientHeight: { value: 500 },
      scrollHeight: { value: 5000 },
    });

    jest.spyOn(scroller, 'getBoundingClientRect').mockReturnValue(new DOMRect(0, 0, 100, 500));
    jest.spyOn(scroller, 'scrollTo');
    document.body.appendChild(scroller);
    enableDragGestures();
  });

  afterEach(() => {
    window.cancelDragging?.();
    delete window.startDragging;
    delete window.updateDragging;
    delete window.cancelDragging;
    scroller.remove();
    jest.restoreAllMocks();
  });

  test('keeps a track drag centered on the thumb after jumping', () => {
    window.startDragging?.(300);
    window.updateDragging?.(310);

    expect(scroller.scrollTo).toHaveBeenNthCalledWith(1, { top: 2750, behavior: 'smooth' });
    expect(scroller.scrollTo).toHaveBeenNthCalledWith(2, { top: 2850, behavior: 'auto' });
  });

  test('uses the centered offset when dragging above the thumb', () => {
    scroller.scrollTop = 2000;
    window.startDragging?.(100);
    window.updateDragging?.(110);

    expect(scroller.scrollTo).toHaveBeenNthCalledWith(1, { top: 750, behavior: 'smooth' });
    expect(scroller.scrollTo).toHaveBeenNthCalledWith(2, { top: 850, behavior: 'auto' });
  });

  test('preserves the grab offset when starting inside the thumb', () => {
    scroller.scrollTop = 1000;
    window.startDragging?.(120);
    expect(scroller.scrollTo).not.toHaveBeenCalled();

    window.updateDragging?.(140);
    expect(scroller.scrollTo).toHaveBeenCalledTimes(1);
    expect(scroller.scrollTo).toHaveBeenCalledWith({ top: 1200, behavior: 'auto' });
  });

  test('converts viewport coordinates relative to the scroller', () => {
    jest.mocked(scroller.getBoundingClientRect).mockReturnValue(new DOMRect(0, 40, 100, 500));
    window.startDragging?.(340);
    window.updateDragging?.(350);

    expect(scroller.scrollTo).toHaveBeenNthCalledWith(1, { top: 2750, behavior: 'smooth' });
    expect(scroller.scrollTo).toHaveBeenNthCalledWith(2, { top: 2850, behavior: 'auto' });
  });

  test('keeps standalone track clicks smooth and ignores updates after cancellation', () => {
    window.startDragging?.(300);
    window.cancelDragging?.();
    window.updateDragging?.(310);

    expect(scroller.scrollTo).toHaveBeenCalledTimes(1);
    expect(scroller.scrollTo).toHaveBeenCalledWith({ top: 2750, behavior: 'smooth' });
  });
});
