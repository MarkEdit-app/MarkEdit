import { Decoration, DOMEventHandlers, EditorView, ViewPlugin } from '@codemirror/view';
import { Range, RangeSet } from '@codemirror/state';

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export function createDecoPlugin(builder: () => RangeSet<Decoration>, eventHandlers?: DOMEventHandlers<any>) {
  return ViewPlugin.fromClass(class {}, {
    provide: () => EditorView.decorations.of(editor => {
      window.editor = editor;
      return builder();
    }),
    eventHandlers,
  });
}

/**
 * Get line deco ranges for a text range, which can be multiple lines.
 */
export function lineDecoRanges(from: number, to: number, className: string, attributes?: { [key: string]: string }) {
  const doc = window.editor.state.doc;
  const decos: Range<Decoration>[] = [];
  const start = doc.lineAt(from).number;
  const end = doc.lineAt(to).number;

  // Generate the range for each line
  for (let index = start; index <= end; ++index) {
    const line = doc.line(index);
    const deco = Decoration.line({ class: className, attributes });
    decos.push(deco.range(line.from, line.from));
  }

  // Ranges are already sorted
  return decos;
}

export function updateStyleSheet(element: HTMLStyleElement | null, update: (style: CSSStyleDeclaration, rule: CSSStyleRule) => void) {
  const rules = element?.sheet?.cssRules;
  if (rules === undefined) {
    return;
  }

  for (let index = 0; index < rules.length; ++index) {
    const rule = rules[index] as CSSStyleRule;
    update(rule.style as CSSStyleDeclaration, rule);
  }
}

/**
 * Returns a css style in { 'color': foo, 'text-shadow': bar } format from a css string like "color: foo; text-shadow: bar".
 *
 * Note that, the input string must exactly follow the format, this is not an error-tolerant approach.
 */
export function shadowableTextColor(input: string) {
  if (!input.includes('; ')) {
    return { 'color': input, 'text-shadow': 'none' };
  }

  const style: { [key: string]: string } = {};
  return input.split('; ').reduce((acc, cur) => {
    const parts = cur.split(': ');
    acc[parts[0]] = parts[1];
    return acc;
  }, style);
}

export function notifyBackgroundColor() {
  const element = window.editor.dom;
  const color = getComputedStyle(element).backgroundColor;
  const match = color.match(/rgb\( *(\d+), *(\d+), *(\d+) *\)/);
  if (match === null) {
    return console.error(`Invalid background color: ${color}`);
  }

  const toHex = (value: string) => parseInt(value).toString(16).padStart(2, '0');
  const red = toHex(match[1]), green = toHex(match[2]), blue = toHex(match[3]);

  // Change it back to number because we only have parsers to handle numbers in native
  const code = parseInt(`${red}${green}${blue}`, 16) as CodeGen_Int;
  window.nativeModules.core.notifyBackgroundColorDidChange({ color: code });
}
