// Jest setup — runs before any test module imports, so module-level constants
// (e.g. `isReleaseMode` in src/common/utils.ts) and CodeMirror internals see
// the polyfills below.

// Pretend we're embedded in WKWebView so `isReleaseMode` is true and debug
// console.log calls are silenced.
(window as unknown as { webkit: unknown }).webkit = { messageHandlers: {} };

// jsdom doesn't implement these; CodeMirror touches all of them during setup.
globalThis.ResizeObserver = class {
  observe() { /* noop */ }
  unobserve() { /* noop */ }
  disconnect() { /* noop */ }
} as unknown as typeof ResizeObserver;

Range.prototype.getClientRects = function () {
  return [] as unknown as DOMRectList;
};

Element.prototype.scrollTo = function () {
  /* noop */
};

window.matchMedia = () => ({
  matches: false,
  addEventListener() { /* noop */ },
  removeEventListener() { /* noop */ },
}) as unknown as MediaQueryList;

if (typeof globalThis.DragEvent === 'undefined') {
  (globalThis as Record<string, unknown>).DragEvent = class DragEvent extends Event {} as unknown as typeof DragEvent;
}

// Globals the editor reads at module load. Tests can overwrite these as needed.
(globalThis as Record<string, unknown>).MarkEdit = {
  editorView: null,
  editorAPI: { setView() { /* noop */ } },
};

window.nativeModules = {
  core: {
    notifyViewDidUpdate() { /* noop */ },
    notifyContentOffsetDidChange() { /* noop */ },
    notifyContentHeightDidChange() { /* noop */ },
    notifyBackgroundColorDidChange() { /* noop */ },
    notifyViewportScaleDidChange() { /* noop */ },
  },
} as unknown as typeof window.nativeModules;
