import { describe, expect, test, beforeEach, afterEach, jest } from '@jest/globals';
import { EditorSelection } from '@codemirror/state';
import { EditorView } from '@codemirror/view';
import { Config } from '../src/config';
import { performTextDrop, resetEditor } from '../src/core';
import { canUndo } from '../src/modules/history';
import normalizeSelection from '../src/modules/selection/normalizeSelection';
import {
  resetCursorPlacementMeasureKey,
  resetScrollRestoreMeasureKey,
} from '../src/modules/reset/transactionMetadata';

// Minimal config
window.config = {
  theme: 'github-light',
  typewriterMode: false,
  focusMode: false,
  readOnlyMode: false,
  showLineNumbers: false,
  showActiveLineIndicator: false,
  lineWrapping: false,
  autoCharacterPairs: false,
  lineHeight: 1.5,
  fontSize: 14,
  fontFace: { family: 'monospace' },
  invisiblesBehavior: 'never',
  indentBehavior: 'never',
} as Config;

describe('Selection clamping logic', () => {
  const doc = 'Hello, World!'; // length = 13

  test('no selection range defaults to cursor at 0', () => {
    const sel = normalizeSelection(doc.length);
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('valid cursor position', () => {
    const sel = normalizeSelection(doc.length, { anchor: 5, head: 5 } as { anchor: CodeGen_Int; head: CodeGen_Int });
    expect(sel.anchor).toBe(5);
    expect(sel.head).toBe(5);
  });

  test('valid selection range', () => {
    const sel = normalizeSelection(doc.length, { anchor: 0, head: 5 } as { anchor: CodeGen_Int; head: CodeGen_Int });
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(5);
  });

  test('anchor and head exceeding length are clamped', () => {
    const sel = normalizeSelection(doc.length, { anchor: 100, head: 200 } as { anchor: CodeGen_Int; head: CodeGen_Int });
    expect(sel.anchor).toBe(doc.length);
    expect(sel.head).toBe(doc.length);
  });

  test('negative values are clamped to 0', () => {
    const sel = normalizeSelection(doc.length, { anchor: -10, head: -5 } as { anchor: CodeGen_Int; head: CodeGen_Int });
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('mixed out-of-bounds values', () => {
    const sel = normalizeSelection(doc.length, { anchor: -1, head: 100 } as { anchor: CodeGen_Int; head: CodeGen_Int });
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(doc.length);
  });

  test('empty document with selection range', () => {
    const sel = normalizeSelection(0, { anchor: 5, head: 10 } as { anchor: CodeGen_Int; head: CodeGen_Int });
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });
});

describe('resetEditor selection', () => {
  function makeScrollToObservable() {
    return jest.spyOn(Element.prototype, 'scrollTo').mockImplementation(function (this: Element, options?: ScrollToOptions | number) {
      if (typeof options === 'object') {
        if (options.top !== undefined) {
          this.scrollTop = options.top;
        }

        if (options.left !== undefined) {
          this.scrollLeft = options.left;
        }
      }
    });
  }

  type TestMeasureRequest = {
    key?: unknown;
    read: (view: EditorView) => unknown;
    write?: (measure: unknown, view: EditorView) => void;
  };

  function isTestMeasureRequest(request: unknown): request is TestMeasureRequest {
    return typeof request === 'object' &&
      request !== null &&
      'key' in request &&
      typeof (request as TestMeasureRequest).read === 'function';
  }

  function mockQueuedAnimationFrames() {
    const callbacks: FrameRequestCallback[] = [];

    jest.spyOn(window, 'requestAnimationFrame').mockImplementation(callback => {
      callbacks.push(callback);
      return callbacks.length;
    });

    return {
      flush() {
        while (callbacks.length > 0) {
          callbacks.shift()?.(0);
        }
      },
      get pendingCount() {
        return callbacks.length;
      },
    };
  }

  beforeEach(() => {
    // Clean up previous editor
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    if (typeof window.editor?.destroy === 'function') {
      window.editor.destroy();
    }

    window.config.readOnlyMode = false;
    window.config.typewriterMode = false;
    window.config.showLineNumbers = false;
    document.body.innerHTML = '';
  });

  afterEach(() => {
    jest.restoreAllMocks();
  });

  test('without selection range, cursor is at 0', async () => {
    await resetEditor('Hello, World!');
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('with valid selection range', async () => {
    await resetEditor('Hello, World!', { anchor: 7 as CodeGen_Int, head: 12 as CodeGen_Int });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(7);
    expect(sel.head).toBe(12);
  });

  test('with cursor position (anchor equals head)', async () => {
    await resetEditor('Hello, World!', { anchor: 5 as CodeGen_Int, head: 5 as CodeGen_Int });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(5);
    expect(sel.head).toBe(5);
  });

  test('selection range exceeding document length is clamped', async () => {
    const content = 'Short';
    await resetEditor(content, { anchor: 100 as CodeGen_Int, head: 200 as CodeGen_Int });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(content.length);
    expect(sel.head).toBe(content.length);
  });

  test('negative selection range is clamped to 0', async () => {
    await resetEditor('Hello', { anchor: -5 as CodeGen_Int, head: -1 as CodeGen_Int });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('empty document with selection range clamps to 0', async () => {
    await resetEditor('', { anchor: 10 as CodeGen_Int, head: 20 as CodeGen_Int });
    const sel = window.editor.state.selection.main;
    expect(sel.anchor).toBe(0);
    expect(sel.head).toBe(0);
  });

  test('document content is preserved', async () => {
    const content = 'Hello, MarkEdit!';
    await resetEditor(content, { anchor: 0 as CodeGen_Int, head: 5 as CodeGen_Int });
    expect(window.editor.state.doc.toString()).toBe(content);
  });

  test('preserves scroll position when requested', async () => {
    makeScrollToObservable();

    await resetEditor(['# Heading', '', 'Body'].join('\n'));
    window.editor.scrollDOM.scrollTop = 240;
    window.editor.scrollDOM.scrollLeft = 12;

    await resetEditor(['# Heading', '', 'Externally changed body'].join('\n'), undefined, {
      preserveScrollPosition: true,
    });

    expect(window.editor.scrollDOM.scrollTop).toBe(240);
    expect(window.editor.scrollDOM.scrollLeft).toBe(12);
  });

  test('updates content in place when preserving scroll and line endings match', async () => {
    makeScrollToObservable();

    await resetEditor(['# Heading', '', 'Body'].join('\n'));
    const editor = window.editor;
    const destroy = jest.spyOn(editor, 'destroy');

    window.editor.dispatch({ selection: EditorSelection.cursor(3) });
    window.editor.scrollDOM.scrollTop = 240;
    window.editor.scrollDOM.scrollLeft = 12;
    const notifyViewDidUpdate = jest.spyOn(window.nativeModules.core, 'notifyViewDidUpdate');
    notifyViewDidUpdate.mockClear();

    await resetEditor(['# Heading', '', 'Externally changed body'].join('\n'), undefined, {
      preserveScrollPosition: true,
    });

    expect(Object.is(window.editor, editor)).toBe(true);
    expect(destroy).not.toHaveBeenCalled();
    expect(window.editor.state.doc.toString()).toBe(['# Heading', '', 'Externally changed body'].join('\n'));
    expect(window.editor.state.selection.main.anchor).toBe(3);
    expect(window.editor.scrollDOM.scrollTop).toBe(240);
    expect(window.editor.scrollDOM.scrollLeft).toBe(12);
    expect(canUndo()).toBe(false);
    expect(notifyViewDidUpdate).not.toHaveBeenCalledWith(expect.objectContaining({
      contentEdited: true,
    }));
    expect(notifyViewDidUpdate).toHaveBeenCalledWith(expect.objectContaining({
      contentEdited: false,
      isDirty: false,
      selectedLineColumn: expect.objectContaining({
        selectionRange: undefined,
      }),
    }));
  });

  test('allows in-place external reloads while read-only mode is enabled', async () => {
    makeScrollToObservable();

    await resetEditor(['# Heading', '', 'Body'].join('\n'));
    window.config.readOnlyMode = true;
    window.editor.scrollDOM.scrollTop = 240;

    await resetEditor(['# Heading', '', 'Externally changed body'].join('\n'), undefined, {
      preserveScrollPosition: true,
    });

    expect(window.editor.state.doc.toString()).toBe(['# Heading', '', 'Externally changed body'].join('\n'));
    expect(window.editor.scrollDOM.scrollTop).toBe(240);
    expect(canUndo()).toBe(false);
  });

  test('clears stale undo history after in-place external reloads', async () => {
    makeScrollToObservable();

    await resetEditor('Original content');
    window.editor.dispatch({
      changes: { from: 0, insert: 'User edited ' },
    });
    expect(canUndo()).toBe(true);

    await resetEditor('Externally changed content', undefined, {
      preserveScrollPosition: true,
    });

    expect(window.editor.state.doc.toString()).toBe('Externally changed content');
    expect(canUndo()).toBe(false);
  });

  test('uses a mapped scroll snapshot and minimal change for in-place external reloads', async () => {
    makeScrollToObservable();

    const targetLine = '- [ ] **Step 7: Add a non-blocking measured-restore and post-restore caret regression test**';
    const content = Array.from({ length: 300 }, (_, index) => {
      if (index === 197) {
        return targetLine;
      }

      return `Line ${index + 1}`;
    }).join('\n');
    const updatedContent = content.replace('- [ ] **Step 7', '- [x] **Step 7');
    const checkboxOffset = content.indexOf('- [ ] **Step 7') + '- ['.length;

    await resetEditor(content);
    window.editor.scrollDOM.scrollTop = 240;

    const dispatch = jest.spyOn(window.editor, 'dispatch');
    const scrollSnapshot = jest.spyOn(window.editor, 'scrollSnapshot');

    await resetEditor(updatedContent, undefined, {
      preserveScrollPosition: true,
    });

    const reloadCall = dispatch.mock.calls.find(call => call.some(spec => (
      typeof spec === 'object' &&
      'changes' in spec
    )));
    if (reloadCall === undefined) {
      throw new Error('Expected an in-place reload dispatch');
    }

    expect(reloadCall).toHaveLength(2);
    expect(scrollSnapshot).toHaveBeenCalledTimes(1);
    expect(reloadCall[0]).toEqual(expect.objectContaining({
      effects: scrollSnapshot.mock.results[0].value,
    }));
    expect(reloadCall[1]).toEqual(expect.objectContaining({
      changes: expect.objectContaining({
        from: checkboxOffset,
        to: checkboxOffset + 1,
      }),
    }));
    expect(String((reloadCall[1] as { changes: { insert: unknown } }).changes.insert)).toBe('x');
    expect(reloadCall[1]).not.toHaveProperty('selection');
  });

  test('uses CodeMirror coordinates for CRLF in-place external reloads', async () => {
    makeScrollToObservable();

    const lineBreak = '\r\n';
    const targetLine = '- [ ] **Step 7: Add a non-blocking measured-restore and post-restore caret regression test**';
    const content = Array.from({ length: 300 }, (_, index) => {
      if (index === 197) {
        return targetLine;
      }

      return `Line ${index + 1}`;
    }).join(lineBreak);
    const updatedContent = content.replace('- [ ] **Step 7', '- [x] **Step 7');
    const checkboxOffset = content.replace(/\r\n/g, '\n').indexOf('- [ ] **Step 7') + '- ['.length;

    await resetEditor(content);
    const editor = window.editor;
    const destroy = jest.spyOn(editor, 'destroy');
    window.editor.scrollDOM.scrollTop = 240;

    const dispatch = jest.spyOn(window.editor, 'dispatch');

    await resetEditor(updatedContent, undefined, {
      preserveScrollPosition: true,
    });

    const reloadCall = dispatch.mock.calls.find(call => call.some(spec => (
      typeof spec === 'object' &&
      'changes' in spec
    )));
    if (reloadCall === undefined) {
      throw new Error('Expected an in-place reload dispatch');
    }

    expect(Object.is(window.editor, editor)).toBe(true);
    expect(destroy).not.toHaveBeenCalled();
    expect(window.editor.state.sliceDoc(0, window.editor.state.doc.length)).toBe(updatedContent);
    expect(reloadCall[1]).toEqual(expect.objectContaining({
      changes: expect.objectContaining({
        from: checkboxOffset,
        to: checkboxOffset + 1,
      }),
    }));
    expect(String((reloadCall[1] as { changes: { insert: unknown } }).changes.insert)).toBe('x');
    expect(window.editor.scrollDOM.scrollTop).toBe(240);
  });

  test('falls back to a rebuild for sparse far-apart external reload changes', async () => {
    makeScrollToObservable();

    const lines = Array.from({ length: 6000 }, (_, index) => `Line ${index + 1}`);
    const updatedLines = [...lines];
    updatedLines[100] = 'Changed line 101';
    updatedLines[5000] = 'Changed line 5001';
    const content = lines.join('\n');
    const updatedContent = updatedLines.join('\n');

    await resetEditor(content);
    const editor = window.editor;
    const destroy = jest.spyOn(editor, 'destroy');
    window.editor.scrollDOM.scrollTop = 240;

    await resetEditor(updatedContent, undefined, {
      preserveScrollPosition: true,
    });

    expect(Object.is(window.editor, editor)).toBe(false);
    expect(destroy).toHaveBeenCalled();
    expect(window.editor.state.doc.toString()).toBe(updatedContent);
    expect(window.editor.scrollDOM.scrollTop).toBe(240);
  });

  test('falls back when a low-ratio sparse reload span exceeds the hard in-place cap', async () => {
    makeScrollToObservable();

    const filler = '0123456789'.repeat(8);
    const lines = Array.from({ length: 3200 }, (_, index) => `Line ${String(index + 1).padStart(4, '0')} ${filler}`);
    const updatedLines = [...lines];
    updatedLines[1000] = `Changed 1001 ${filler}`;
    updatedLines[1300] = `Changed 1301 ${filler}`;
    const content = lines.join('\n');
    const updatedContent = updatedLines.join('\n');

    await resetEditor(content);
    const editor = window.editor;
    const destroy = jest.spyOn(editor, 'destroy');
    window.editor.scrollDOM.scrollTop = 240;

    await resetEditor(updatedContent, undefined, {
      preserveScrollPosition: true,
    });

    expect(Object.is(window.editor, editor)).toBe(false);
    expect(destroy).toHaveBeenCalled();
    expect(window.editor.state.doc.toString()).toBe(updatedContent);
    expect(window.editor.scrollDOM.scrollTop).toBe(240);
  });

  test('reports clean state when an in-place external reload replaces dirty content', async () => {
    makeScrollToObservable();

    await resetEditor('Original content');
    window.editor.dispatch({
      changes: { from: 0, insert: 'User edited ' },
    });
    expect(canUndo()).toBe(true);

    const notifyViewDidUpdate = jest.spyOn(window.nativeModules.core, 'notifyViewDidUpdate');
    notifyViewDidUpdate.mockClear();

    await resetEditor('Externally changed content', undefined, {
      preserveScrollPosition: true,
    });

    expect(window.editor.state.doc.toString()).toBe('Externally changed content');
    expect(canUndo()).toBe(false);
    expect(notifyViewDidUpdate).toHaveBeenCalledWith(expect.objectContaining({
      contentEdited: false,
      isDirty: false,
    }));
  });

  test('does not publish restorable selection after line-number refresh for in-place external reloads', async () => {
    makeScrollToObservable();
    const animationFrames = mockQueuedAnimationFrames();

    window.config.showLineNumbers = true;

    await resetEditor(['# Heading', '', 'Body'].join('\n'));
    window.editor.dispatch({ selection: EditorSelection.cursor(3) });

    const notifyViewDidUpdate = jest.spyOn(window.nativeModules.core, 'notifyViewDidUpdate');
    notifyViewDidUpdate.mockClear();

    await resetEditor(['# Heading', '', 'Externally changed body'].join('\n'), undefined, {
      preserveScrollPosition: true,
    });

    notifyViewDidUpdate.mockClear();
    animationFrames.flush();

    expect(notifyViewDidUpdate).not.toHaveBeenCalledWith(expect.objectContaining({
      selectedLineColumn: expect.objectContaining({
        selectionRange: expect.anything(),
      }),
    }));
  });

  test('preserves scroll during typewriter-mode in-place external reloads', async () => {
    makeScrollToObservable();

    await resetEditor(['# Heading', '', 'Body'].join('\n'));
    window.config.typewriterMode = true;
    window.editor.scrollDOM.scrollTop = 240;

    await resetEditor(['# Heading', '', 'Externally changed body'].join('\n'), undefined, {
      preserveScrollPosition: true,
    });

    expect(window.editor.scrollDOM.scrollTop).toBe(240);
  });

  test('scrolls to top by default when no selection is restored', async () => {
    makeScrollToObservable();

    await resetEditor(['# Heading', '', 'Body'].join('\n'));
    window.editor.scrollDOM.scrollTop = 240;

    await resetEditor(['# Heading', '', 'New body'].join('\n'));

    expect(window.editor.scrollDOM.scrollTop).toBe(0);
  });

  test('moves the cursor into the restored viewport on fallback rebuilds without publishing a restorable range', async () => {
    makeScrollToObservable();

    const content = Array.from({ length: 200 }, (_, index) => `Line ${index + 1}`).join('\n');
    const fallbackContent = content.replace(/\n/g, '\r\n');
    await resetEditor(content);
    window.editor.scrollDOM.scrollTop = 240;

    const notifyViewDidUpdate = jest.spyOn(window.nativeModules.core, 'notifyViewDidUpdate');

    await resetEditor(fallbackContent, undefined, {
      preserveScrollPosition: true,
    });

    const expectedAnchor = window.editor.lineBlockAtHeight(240).from;
    expect(expectedAnchor).toBeGreaterThan(0);
    expect(window.editor.state.selection.main.anchor).toBe(expectedAnchor);
    expect(window.editor.state.selection.main.head).toBe(expectedAnchor);
    expect(canUndo()).toBe(false);
    expect(notifyViewDidUpdate).not.toHaveBeenCalledWith(expect.objectContaining({
      selectedLineColumn: expect.objectContaining({
        selectionRange: {
          anchor: expectedAnchor,
          head: expectedAnchor,
        },
      }),
    }));
  });

  test('keeps restored viewport when fallback cursor placement scrolls selection into view', async () => {
    makeScrollToObservable();

    const content = Array.from({ length: 200 }, (_, index) => `Line ${index + 1}`).join('\n');
    const fallbackContent = content.replace(/\n/g, '\r\n');
    await resetEditor(content);
    window.editor.scrollDOM.scrollTop = 240;

    const originalDispatch = EditorView.prototype.dispatch;
    jest.spyOn(EditorView.prototype, 'dispatch').mockImplementation(function (
      this: EditorView,
      ...specs: Parameters<EditorView['dispatch']>
    ) {
      originalDispatch.apply(this, specs);

      if (specs.some(spec => typeof spec === 'object' && 'selection' in spec)) {
        this.scrollDOM.scrollTop = 999;
      }
    });

    await resetEditor(fallbackContent, undefined, {
      preserveScrollPosition: true,
    });

    expect(window.editor.scrollDOM.scrollTop).toBe(240);
  });

  test('places fallback reset cursor near the viewport midpoint when layout is available', async () => {
    makeScrollToObservable();

    const content = Array.from({ length: 200 }, (_, index) => `Line ${index + 1}`).join('\n');
    const fallbackContent = content.replace(/\n/g, '\r\n');
    await resetEditor(content);
    window.editor.scrollDOM.scrollTop = 240;

    jest.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue({
      x: 10,
      y: 20,
      width: 300,
      height: 400,
      top: 20,
      right: 310,
      bottom: 420,
      left: 10,
      toJSON: () => ({}),
    });
    const posAtCoords = jest.spyOn(EditorView.prototype, 'posAtCoords').mockReturnValue(123);

    await resetEditor(fallbackContent, undefined, {
      preserveScrollPosition: true,
    });

    expect(posAtCoords.mock.calls).toContainEqual([{
      x: 160,
      y: 220,
    }, false]);
    expect(window.editor.state.selection.main.anchor).toBe(123);
    expect(window.editor.scrollDOM.scrollTop).toBe(240);
  });

  test('does not wait for measured restore and places cursor after delayed fallback restore', async () => {
    makeScrollToObservable();
    const animationFrames = mockQueuedAnimationFrames();

    const content = Array.from({ length: 200 }, (_, index) => `Line ${index + 1}`).join('\n');
    const fallbackContent = content.replace(/\n/g, '\r\n');
    await resetEditor(content);
    window.editor.scrollDOM.scrollTop = 240;

    const requestMeasure = jest.spyOn(EditorView.prototype, 'requestMeasure').mockImplementation(() => {});
    const measureRequests = () => requestMeasure.mock.calls
      .map(([request]) => request)
      .filter(isTestMeasureRequest);
    const measureRequestsFor = (key: string) => measureRequests()
      .filter(request => request.key === key);
    const onlyMeasureRequestFor = (key: string) => {
      const requests = measureRequestsFor(key);
      expect(requests).toHaveLength(1);
      return requests[0];
    };

    let timeout: ReturnType<typeof setTimeout> | undefined;
    const result = await Promise.race([
      resetEditor(fallbackContent, undefined, { preserveScrollPosition: true }).then(() => 'resolved'),
      new Promise(resolve => {
        timeout = setTimeout(() => resolve('timed out'), 250);
      }),
    ]).finally(() => {
      if (timeout !== undefined) {
        clearTimeout(timeout);
      }
    });

    expect(result).toBe('resolved');

    const restoreRequest = onlyMeasureRequestFor(resetScrollRestoreMeasureKey);
    const restoreMeasure = restoreRequest.read(window.editor);
    restoreRequest.write?.(restoreMeasure, window.editor);

    expect(measureRequestsFor(resetCursorPlacementMeasureKey)).toHaveLength(0);
    expect(animationFrames.pendingCount).toBeGreaterThan(0);
    animationFrames.flush();
    const cursorRequest = onlyMeasureRequestFor(resetCursorPlacementMeasureKey);
    const cursorMeasure = cursorRequest.read(window.editor);
    cursorRequest.write?.(cursorMeasure, window.editor);

    const expectedAnchor = window.editor.lineBlockAtHeight(240).from;
    expect(window.editor.scrollDOM.scrollTop).toBe(240);
    expect(window.editor.state.selection.main.anchor).toBe(expectedAnchor);
    expect(window.editor.state.selection.main.head).toBe(expectedAnchor);

    const staleScrollDOM = window.editor.scrollDOM;
    await resetEditor('Replacement editor');
    staleScrollDOM.scrollTop = 0;
    restoreRequest.write?.(restoreMeasure, window.editor);
    cursorRequest.write?.(cursorMeasure, window.editor);
    expect(staleScrollDOM.scrollTop).toBe(0);
  });

  test('ignores stale delayed fallback restores after a newer in-place reload', async () => {
    makeScrollToObservable();
    const animationFrames = mockQueuedAnimationFrames();

    const content = Array.from({ length: 200 }, (_, index) => `Line ${index + 1}`).join('\n');
    const fallbackContent = content.replace(/\n/g, '\r\n');
    const updatedFallbackContent = fallbackContent.replace('Line 150', 'Changed line 150');
    await resetEditor(content);
    window.editor.scrollDOM.scrollTop = 240;

    const requestMeasure = jest.spyOn(EditorView.prototype, 'requestMeasure').mockImplementation(() => {});
    const measureRequests = () => requestMeasure.mock.calls
      .map(([request]) => request)
      .filter(isTestMeasureRequest);
    const measureRequestsFor = (key: string) => measureRequests()
      .filter(request => request.key === key);
    const onlyMeasureRequestFor = (key: string) => {
      const requests = measureRequestsFor(key);
      expect(requests).toHaveLength(1);
      return requests[0];
    };

    await resetEditor(fallbackContent, undefined, { preserveScrollPosition: true });

    const editor = window.editor;
    const restoreRequest = onlyMeasureRequestFor(resetScrollRestoreMeasureKey);
    const restoreMeasure = restoreRequest.read(editor);
    editor.scrollDOM.scrollTop = 480;

    await resetEditor(updatedFallbackContent, undefined, { preserveScrollPosition: true });
    expect(Object.is(window.editor, editor)).toBe(true);
    expect(window.editor.scrollDOM.scrollTop).toBe(480);

    const pendingFramesBeforeStaleRestore = animationFrames.pendingCount;
    restoreRequest.write?.(restoreMeasure, editor);
    expect(window.editor.scrollDOM.scrollTop).toBe(480);
    expect(animationFrames.pendingCount).toBe(pendingFramesBeforeStaleRestore);

    animationFrames.flush();

    expect(measureRequestsFor(resetCursorPlacementMeasureKey)).toHaveLength(0);
    expect(window.editor.scrollDOM.scrollTop).toBe(480);
  });

  test('restored selection wins over a scroll preservation request', async () => {
    const scrollTo = makeScrollToObservable();

    await resetEditor(['# Heading', '', 'Body'].join('\n'));
    window.editor.scrollDOM.scrollTop = 240;

    await resetEditor(
      ['# Heading', '', 'Externally changed body'].join('\n'),
      { anchor: 5 as CodeGen_Int, head: 5 as CodeGen_Int },
      { preserveScrollPosition: true },
    );

    expect(window.editor.state.selection.main.anchor).toBe(5);
    expect(window.editor.state.selection.main.head).toBe(5);
    expect(scrollTo.mock.calls).not.toContainEqual([expect.objectContaining({ top: 240 })]);
  });
});

describe('performTextDrop', () => {
  beforeEach(() => {
    // eslint-disable-next-line @typescript-eslint/no-unnecessary-condition
    if (typeof window.editor?.destroy === 'function') {
      window.editor.destroy();
    }

    document.body.innerHTML = '';
  });

  // Inject a fake `.cm-dropCursor` element into the editor's scrollDOM so the lookup
  // succeeds, and stub `posAtCoords` to return the desired document position (jsdom
  // doesn't compute layout, so the real method always returns null).
  function fakeDropCursor(pos: number | null) {
    const cursor = document.createElement('div');
    cursor.className = 'cm-dropCursor';
    window.editor.scrollDOM.appendChild(cursor);

    Object.defineProperty(window.editor, 'posAtCoords', {
      configurable: true,
      value: () => pos,
    });
  }

  test('inserts text at the drop cursor position', async () => {
    await resetEditor('Hello, World!');
    fakeDropCursor(7);

    performTextDrop('there ');
    expect(window.editor.state.doc.toString()).toBe('Hello, there World!');
  });

  test('moves the caret to after the inserted text', async () => {
    await resetEditor('Hello, World!');
    fakeDropCursor(7);

    performTextDrop('there ');
    expect(window.editor.state.selection.main.head).toBe(13);
  });

  test('falls back to replacing the selection when no drop cursor is present', async () => {
    await resetEditor('Hello, World!');
    window.editor.dispatch({ selection: EditorSelection.range(7, 12) });

    performTextDrop('Earth');
    expect(window.editor.state.doc.toString()).toBe('Hello, Earth!');
  });

  test('falls back when posAtCoords returns null', async () => {
    await resetEditor('Hello, World!');
    fakeDropCursor(null);
    window.editor.dispatch({ selection: EditorSelection.range(7, 12) });

    performTextDrop('Earth');
    expect(window.editor.state.doc.toString()).toBe('Hello, Earth!');
  });
});
