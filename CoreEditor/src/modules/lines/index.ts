import { Line } from '@codemirror/state';
import { almostEqual, getFontSizeValue } from '../../common/utils';

export function linesWithRange(from: number, to: number) {
  const editor = window.editor;
  const doc = editor.state.doc;

  const lines: Line[] = [];
  const start = doc.lineAt(from).number;
  const end = doc.lineAt(to).number;

  for (let ln = start; ln <= end; ++ln) {
    lines.push(doc.line(ln));
  }

  return lines;
}

export function getVisibleLines() {
  const ranges = window.editor.visibleRanges;
  const lines = ranges.map(({ from, to }) => linesWithRange(from, to)).flat();
  return lines;
}

export function getLineElement(pos: number): HTMLElement | null {
  let node: Node | null = window.editor.domAtPos(pos).node;
  while (node && !(node instanceof HTMLElement && node.classList.contains('cm-line'))) {
    node = node.parentNode;
  }

  return node;
}

/**
 * Round the `.cm-gutters` to a whole pixel, its intrinsic width is otherwise sub-pixel.
 *
 * This is to avoid rendering issues like visible whitespaces partially hiding letters.
 */
export function observeGuttersWidth(gutters: HTMLElement) {
  const requestMeasure = (element: HTMLElement) => {
    // Drop our own padding first, the base must come from style sheets only
    element.style.paddingRight = '';
    const base = parseFloat(getComputedStyle(element).paddingRight) || 0;
    const width = element.getBoundingClientRect().width;
    if (width > 0) {
      element.style.paddingRight = `${base + Math.ceil(width) - width}px`;
    }
  };

  storage.gutterObserver ??= new ResizeObserver(entries => {
    entries.forEach(entry => requestMeasure(entry.target as HTMLElement));
  });

  storage.gutterObserver.disconnect();
  storage.gutterObserver.observe(gutters);
  requestMeasure(gutters);
}

export function adjustActiveLineGutter() {
  if (!window.config.showLineNumbers) {
    return;
  }

  const { selection, doc } = window.editor.state;
  const { from: lineFrom, number: lineNumber } = doc.lineAt(selection.main.from);
  const lineElement = getLineElement(lineFrom);
  if (lineElement === null) {
    return;
  }

  const gutterElement = findLineNumberGutter(lineNumber);
  if (gutterElement !== null) {
    const height = lineElement.getBoundingClientRect().height;
    gutterElement.style.height = `${height}px`;
  }
}

export function adjustGutterPositions(className: 'lineNumbers' | 'gutterHover' = 'lineNumbers') {
  if (!window.config.showLineNumbers) {
    return;
  }

  const gutterElements = queryGutters(`.cm-${className} .cm-gutterElement`);
  if (gutterElements.length === 0) {
    return;
  }

  // Checked before reading any rect, headings are the only reason to realign gutters
  const headingLines = [...document.querySelectorAll('.cm-line:has(.cm-md-header)')];
  if (headingLines.length === 0) {
    return;
  }

  // Batch the measurements, interleaving them with style writes forces a re-layout per read
  const gutterRects = gutterElements.map(element => element.getBoundingClientRect());
  const updates: { element: HTMLElement; paddingTop: number }[] = [];
  headingLines.forEach(lineEl => {
    const { fontSize } = getComputedStyle(lineEl);
    if (almostEqual(getFontSizeValue(fontSize), window.config.fontSize)) {
      return;
    }

    const element = findGutter(gutterElements, gutterRects, lineEl.getBoundingClientRect());
    if (element !== undefined) {
      updates.push({
        element,
        paddingTop: getGutterPadding(element, fontSize),
      });
    }
  });

  updates.forEach(({ element, paddingTop }) => {
    element.style.paddingTop = `${paddingTop}px`;
  });
}

/**
 * Find the active line-number gutter for a given line.
 *
 * Only active-line gutters are queried, which excludes CodeMirror's hidden width spacer (its
 * text rounds up to all-nines, e.g. "9", and would otherwise collide with single-digit line numbers).
 */
export function findLineNumberGutter(lineNumber: number): HTMLElement | null {
  const elements = [...document.querySelectorAll('.cm-lineNumbers .cm-activeLineGutter')] as HTMLElement[];
  return elements.find(element => Number(element.textContent) === lineNumber) ?? null;
}

function findGutter(elements: HTMLElement[], rects: DOMRect[], anchor: DOMRect) {
  const middle = (anchor.bottom + anchor.top) * 0.5;
  const index = rects.findIndex(rect => rect.top < middle && rect.bottom > middle);
  return index < 0 ? undefined : elements[index];
}

function queryGutters(selector: string) {
  const elements = [...document.querySelectorAll(selector)] as HTMLElement[];
  elements.forEach(element => {
    // Guarded, an unconditional write would invalidate the layout even when nothing was set
    if (element.style.paddingTop !== '') {
      element.style.paddingTop = '';
    }
  });

  return elements;
}

function getGutterPadding(element: HTMLElement, targetFontSize: string) {
  const { fontSize, fontFamily } = getComputedStyle(element);
  const text = element.textContent;
  return measureHeight(text, `${targetFontSize} ${fontFamily}`) - measureHeight(text, `${fontSize} ${fontFamily}`);
}

function measureHeight(text: string, font: string) {
  const key = text + font;
  const cachedValue = storage.cachedHeights[key];
  if (cachedValue) {
    return cachedValue;
  }

  const context = canvas.getContext('2d') as CanvasRenderingContext2D;
  context.font = font;

  const metrics = context.measureText(text);
  const height = metrics.actualBoundingBoxAscent + metrics.actualBoundingBoxDescent;

  storage.cachedHeights[key] = height;
  return height;
}

const canvas = document.createElement('canvas');

const storage: {
  cachedHeights: { [key: string]: number };
  gutterObserver: ResizeObserver | undefined;
} = {
  cachedHeights: {},
  gutterObserver: undefined,
};
