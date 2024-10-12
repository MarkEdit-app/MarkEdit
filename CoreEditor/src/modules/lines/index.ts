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

export function adjustGutterPositions(className: 'lineNumbers' | 'gutterHover' = 'lineNumbers') {
  if (!window.config.showLineNumbers) {
    return;
  }

  const gutterElements = queryGutters(`.cm-${className} .cm-gutterElement`);
  if (gutterElements.length === 0) {
    return;
  }

  const lineElements = document.querySelectorAll('.cm-line:has(.cm-md-header)');
  lineElements.forEach(lineEl => {
    const { fontSize } = getComputedStyle(lineEl);
    if (almostEqual(getFontSizeValue(fontSize), window.config.fontSize)) {
      return;
    }

    const lineRect = lineEl.getBoundingClientRect();
    adjustGutter(findGutter(gutterElements, lineRect), fontSize);
  });
}

function findGutter(elements: HTMLElement[], anchor: DOMRect) {
  const middle = (anchor.bottom + anchor.top) * 0.5;
  return elements.find(element => {
    const rect = element.getBoundingClientRect();
    return rect.top < middle && rect.bottom > middle;
  });
}

function queryGutters(selector: string) {
  const elements = [...document.querySelectorAll(selector)] as HTMLElement[];
  elements.forEach(element => element.style.paddingTop = '');
  return elements;
}

function adjustGutter(element: HTMLElement | undefined, targetFontSize: string) {
  if (element === undefined) {
    return;
  }

  const { fontSize, fontFamily } = getComputedStyle(element);
  const paddingTop = getHeightDiff(element.textContent ?? '', targetFontSize, fontSize, fontFamily);
  element.style.paddingTop = `${paddingTop}px`;
}

function getHeightDiff(text: string, targetFontSize: string, baseFontSize: string, fontFamily: string) {
  const targetHeight = measureHeight(text, `${targetFontSize} ${fontFamily}`);
  const baseHeight = measureHeight(text, `${baseFontSize} ${fontFamily}`);
  return targetHeight - baseHeight;
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
} = {
  cachedHeights: {},
};
