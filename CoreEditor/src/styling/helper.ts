import { Decoration, DOMEventHandlers, EditorView, ViewPlugin } from '@codemirror/view';
import { RangeSet } from '@codemirror/state';

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

  return input.split('; ').reduce((acc, cur) => {
    const parts = cur.split(': ');
    acc[parts[0]] = parts[1];
    return acc;
  }, {});
}
