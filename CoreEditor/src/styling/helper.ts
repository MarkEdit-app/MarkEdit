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
export function lineDecoRanges(from: number, to: number, className: string) {
  const doc = window.editor.state.doc;
  const decos: Range<Decoration>[] = [];
  const start = doc.lineAt(from).number;
  const end = doc.lineAt(to).number;

  // Generate the range for each line
  for (let index = start; index <= end; ++index) {
    const line = doc.line(index);
    const deco = Decoration.line({ class: className });
    decos.push(deco.range(line.from, line.from));
  }

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
