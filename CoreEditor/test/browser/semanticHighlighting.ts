import { EditorView } from '@codemirror/view';
import { forceParsing, highlightingFor } from '@codemirror/language';
import { markdown, markdownLanguage } from '@codemirror/lang-markdown';
import { html } from '@codemirror/lang-html';
import { bundledLanguages } from '../../src/languages';
import { classHighlighters, markdownExtensions } from '../../src/styling/markdown';
import { loadTheme } from '../../src/styling/themes';
import { tags } from '../../src/styling/builder';
import fixture from '../fixtures/semantic-theme.css?raw';

const source = [
  '**bold** *italic* ~~strike~~ `inline` [link](https://example.com)',
  '> quote',
  '```html\n<span title="text">content</span>\n<!-- comment -->\n```',
].join('\n\n');

const selectors = {
  bold: '.cm-markedit-markdown-bold:not(.cm-markedit-markdown-marker)',
  italic: '.cm-markedit-markdown-italic:not(.cm-markedit-markdown-marker)',
  strike: '.cm-markedit-markdown-strikethrough:not(.cm-markedit-markdown-marker)',
  quote: '.cm-markedit-markdown-quote:not(.cm-markedit-markdown-marker)',
  inlineCode: '.cm-markedit-markdown-inline-code',
  link: '.cm-markedit-markdown-link:not(.cm-markedit-markdown-marker)',
  boldMarker: '.cm-markedit-markdown-bold.cm-markedit-markdown-marker',
  codeMarker: '.cm-line:has(.cm-md-codeInfo) .cm-markedit-markdown-code-marker',
  tag: '.cm-markedit-syntax-tag',
  string: '.cm-markedit-syntax-string',
  comment: '.cm-markedit-syntax-comment',
  standardFunction: '.cm-markedit-syntax-function.cm-markedit-syntax-constant',
};

const properties = [
  'color',
  'text-shadow',
  'font-weight',
  'font-style',
  'text-decoration-line',
];

function equal(actual: string, expected: string, label: string) {
  if (actual !== expected) {
    throw new Error(`${label}: expected ${expected}, received ${actual}`);
  }
}

function run(theme: string) {
  const htmlLanguage = html().language;
  const view = new EditorView({
    doc: source,
    parent: document.body,
    extensions: [
      EditorView.editable.of(false),
      markdown({
        base: markdownLanguage,
        extensions: markdownExtensions,
        codeLanguages: info => info === 'html' ? htmlLanguage : null,
      }),
      classHighlighters,
      loadTheme(theme).extension,
    ],
  });

  const style = document.createElement('style');
  try {
    if (!forceParsing(view, view.state.doc.length)) {
      throw new Error(`${theme}: document did not finish parsing`);
    }

    // The HTML fixture has no standard-function tokens; use the real highlighter for this tag combination
    const classes = highlightingFor(view.state, [tags.standard(tags.function(tags.variableName))]);
    if (classes === null) {
      throw new Error('Standard function was not highlighted');
    }

    const standardFunction = view.contentDOM.appendChild(document.createElement('span'));
    standardFunction.className = classes;
    standardFunction.textContent = 'standardFunction';

    const elements = Object.fromEntries(Object.entries(selectors).map(([name, selector]) => {
      const element = view.dom.querySelector<HTMLElement>(selector);
      if (element === null) {
        throw new Error(`${theme}: missing ${name} token`);
      }

      return [name, element] as const;
    }));

    const sample = () => Object.fromEntries(Object.entries(elements).map(([name, element]) => {
      const computed = getComputedStyle(element);
      return [name, Object.fromEntries(properties.map(property => [property, computed.getPropertyValue(property)]))];
    }));

    const before = sample();
    if (theme === 'synthwave84' && before.quote['text-shadow'] === 'none') {
      throw new Error('SynthWave quote must exercise a nonempty shadow');
    }

    style.textContent = fixture;
    document.head.appendChild(style);

    const customized = sample();
    const colors: Record<keyof typeof selectors, string> = {
      bold: 'rgb(235, 203, 139)', italic: 'rgb(180, 142, 173)', strike: 'rgb(191, 97, 106)',
      quote: 'rgb(163, 190, 140)', inlineCode: 'rgb(143, 188, 187)', link: 'rgb(129, 161, 193)',
      boldMarker: 'rgb(124, 138, 159)', codeMarker: 'rgb(208, 135, 112)',
      tag: 'rgb(255, 203, 107)', string: 'rgb(195, 232, 141)', comment: 'rgb(135, 150, 176)',
      standardFunction: 'rgb(255, 203, 107)',
    };

    for (const [name, color] of Object.entries(colors)) {
      equal(customized[name].color, color, `${theme}/${name}/color`);
      for (const property of ['font-weight', 'font-style', 'text-decoration-line']) {
        equal(customized[name][property], before[name][property], `${theme}/${name}/${property}`);
      }
    }

    for (const name of ['quote', 'inlineCode', 'link']) {
      equal(customized[name]['text-shadow'], 'none', `${theme}/${name}/text-shadow`);
    }

    const rule = style.sheet?.cssRules[0];
    if (!(rule instanceof CSSStyleRule)) {
      throw new Error('Semantic theme fixture is missing its variable rule');
    }

    rule.style.setProperty('--markedit-syntax-constant-color', '#123456');
    rule.style.setProperty('--markedit-syntax-constant-text-shadow', '0 0 2px #123456');
    equal(getComputedStyle(standardFunction).color, colors.standardFunction, `${theme}/function over constant/color`);
    equal(getComputedStyle(standardFunction).textShadow, 'none', `${theme}/function over constant/shadow`);

    rule.style.removeProperty('--markedit-syntax-function-color');
    rule.style.removeProperty('--markedit-syntax-function-text-shadow');
    equal(getComputedStyle(standardFunction).color, 'rgb(18, 52, 86)', `${theme}/constant fallback/color`);
    equal(getComputedStyle(standardFunction).textShadow, 'rgb(18, 52, 86) 0px 0px 2px', `${theme}/constant fallback/shadow`);

    rule.style.removeProperty('--markedit-syntax-tag-color');
    equal(getComputedStyle(elements.tag).color, 'rgb(216, 222, 233)', `${theme}/general name fallback`);

    rule.style.removeProperty('--markedit-markdown-code-marker-color');
    equal(getComputedStyle(elements.codeMarker).color, 'rgb(124, 138, 159)', `${theme}/general marker fallback`);

    style.remove();
    const restored = sample();

    for (const name of Object.keys(selectors)) {
      for (const property of properties) {
        equal(restored[name][property], before[name][property], `${theme}/${name}/restored ${property}`);
      }
    }
  } finally {
    style.remove();
    view.destroy();
    view.dom.remove();
  }
}

async function runNestedMarkdown() {
  const languages = bundledLanguages(html());
  const nested = languages.find(language => language.name === 'Markdown');
  if (nested === undefined) {
    throw new Error('Bundled Markdown language is missing');
  }

  const updated = await nested.load();
  const original = markdown();
  const doc = '~~~~markdown\n`nestedInline`\n\n10. nestedItem\n\n> nestedQuote\n\n[nestedLink](https://example.com)\n\n```inner\nbody\n```\n~~~~';

  const createView = (language: typeof updated.language) => new EditorView({
    doc,
    parent: document.body,
    extensions: [
      EditorView.editable.of(false),
      EditorView.editorAttributes.of({ style: 'position: absolute; top: 0; left: 0;' }),
      markdown({
        base: markdownLanguage,
        extensions: markdownExtensions,
        codeLanguages: info => info === 'markdown' ? language : null,
      }),
      classHighlighters,
      loadTheme('synthwave84').extension,
    ],
  });

  const reference = createView(original.language);
  const view = createView(updated.language);
  const style = document.createElement('style');

  try {
    if (!forceParsing(reference, doc.length) || !forceParsing(view, doc.length)) {
      throw new Error('Nested Markdown did not finish parsing');
    }

    const cases = [
      { text: 'nestedInline', role: 'inline-code', color: 'rgb(143, 188, 187)' },
      { text: '10.', role: 'list-marker', color: 'rgb(124, 138, 159)' },
      { text: '> nestedQuote', role: 'quote-marker', color: 'rgb(124, 138, 159)' },
      { text: '[nestedLink]', role: 'link-marker', color: 'rgb(124, 138, 159)' },
      { text: '```inner', role: 'code-marker', color: 'rgb(208, 135, 112)' },
      { text: 'inner', role: 'code-info', color: 'rgb(136, 68, 34)' },
    ];

    const elementAt = (editor: EditorView, text: string) => {
      const { node } = editor.domAtPos(doc.indexOf(text), 1);
      const element = node instanceof Element ? node : node.parentElement;
      if (element === null) {
        throw new Error(`Missing nested Markdown token: ${text}`);
      }

      return element;
    };

    const comparedProperties = [...properties, 'font-family'];
    const baseline = cases.map(({ text, role }) => {
      const element = elementAt(view, text);
      if (!element.classList.contains(`cm-markedit-markdown-${role}`)) {
        throw new Error(`Missing nested Markdown role: ${role}`);
      }

      const before = getComputedStyle(elementAt(reference, text));
      const after = getComputedStyle(element);
      return Object.fromEntries(comparedProperties.map(property => {
        const value = before.getPropertyValue(property);
        equal(after.getPropertyValue(property), value, `nested/${role}/baseline ${property}`);
        return [property, value];
      }));
    });

    style.textContent = fixture;
    document.head.appendChild(style);
    const rule = style.sheet?.cssRules[0];
    if (!(rule instanceof CSSStyleRule)) {
      throw new Error('Nested Markdown fixture is missing its variable rule');
    }

    rule.style.setProperty('--markedit-markdown-code-info-color', '#884422');
    for (const { text, role, color } of cases) {
      equal(getComputedStyle(elementAt(view, text)).color, color, `nested/${role}/override`);
    }

    style.remove();
    cases.forEach(({ text, role }, index) => {
      const restored = getComputedStyle(elementAt(view, text));
      for (const property of comparedProperties) {
        equal(restored.getPropertyValue(property), baseline[index][property], `nested/${role}/restored ${property}`);
      }
    });
  } finally {
    style.remove();
    reference.destroy();
    reference.dom.remove();
    view.destroy();
    view.dom.remove();
  }
}

try {
  for (const theme of ['github-light', 'synthwave84']) {
    run(theme);
  }

  await runNestedMarkdown();
  window.dispatchEvent(new CustomEvent('semantic-theme-result', {
    detail: { passed: true, message: 'Semantic fixture application, precedence and restoration: github-light, synthwave84, nested Markdown' },
  }));
} catch (error) {
  window.dispatchEvent(new CustomEvent('semantic-theme-result', {
    detail: { passed: false, message: error instanceof Error ? `${error.message}\n${error.stack ?? ''}` : String(error) },
  }));
}
