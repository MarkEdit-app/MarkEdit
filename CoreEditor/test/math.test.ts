import { describe, expect, test } from '@jest/globals';
import { EditorView } from '@codemirror/view';
import { foldable, syntaxTree } from '@codemirror/language';
import { parser as markdownParser, parseCode } from '@lezer/markdown';
import { TreeFragment } from '@lezer/common';
import { markdownMathExtension } from '../src/modules/math';
import { getNodesNamed } from '../src/modules/lezer';
import { previewMath } from '../src/styling/nodes/math';
import * as editor from './utils/editor';

describe('Math parser', () => {
  test('test BlockMath', () => {
    editor.setUp('$$\nx = 1\n$$');
    expect(parseTypes(window.editor)).toContain('BlockMath');
  });

  test('test BlockMath with leading spaces', () => {
    editor.setUp('   $$\nx = 1\n$$');
    expect(parseTypes(window.editor)).toContain('BlockMath');
  });

  test('test BlockMath with trailing spaces', () => {
    editor.setUp('$$   \nx = 1\n$$   ');
    expect(parseTypes(window.editor)).toContain('BlockMath');
  });

  test('test BlockMath with leading and trailing spaces', () => {
    editor.setUp('  $$  \nx = 1\n  $$  ');
    expect(parseTypes(window.editor)).toContain('BlockMath');
  });

  test('test BlockMath single line', () => {
    editor.setUp('$$x = 1$$');
    expect(parseTypes(window.editor)).toContain('BlockMath');
  });

  test('test BlockMath with blank lines', () => {
    editor.setUp('$$\n\nx = 1\n\n$$\n\n## Heading');
    const types = parseTypes(window.editor);
    expect(types).toContain('BlockMath');
    expect(types).toContain('ATXHeading2');
  });

  test.each(['$$', '$$x = 1', '$$\n\n## Heading', '$$\nx = 1\n## Heading'])('test unclosed BlockMath: %s', source => {
    editor.setUp(source);
    const types = parseTypes(window.editor);
    expect(types).not.toContain('BlockMath');
    if (source.includes('## Heading')) {
      expect(types).toContain('ATXHeading2');
    }
  });

  test('test BlockMath in blockquote', () => {
    editor.setUp('> $$\n> x = 1\n> $$');
    expect(parseTypes(window.editor)).toContain('BlockMath');
  });

  test('test unclosed BlockMath in blockquote', () => {
    editor.setUp('> $$\n>\n> ## Heading');
    const types = parseTypes(window.editor);
    expect(types).not.toContain('BlockMath');
    expect(types).toContain('Blockquote');
    expect(types).toContain('ATXHeading2');
  });

  test('unclosed math preserves heading siblings and folding', () => {
    const source = '# First\n\n$$\n\n# Second\n\ntext';
    editor.setUp(source);
    const headings = getNodesNamed(window.editor.state, ['ATXHeading1']);
    expect(headings[0].node.nextSibling?.name).toBe('Paragraph');
    expect(headings[0].node.nextSibling?.nextSibling?.from).toBe(headings[1].from);
    expect(foldable(window.editor.state, 0, 7)).toEqual({ from: 7, to: source.indexOf('# Second') - 1 });
  });

  test.each([
    '> intro\n>\n> $$\n> x = 1\n\n## Outside',
    '> $$\n> x = 1\n\n## Outside\n$$',
  ])('math does not consume text outside a quote: %s', source => {
    editor.setUp(source);
    expect(getNodesNamed(window.editor.state, ['BlockMath'])).toHaveLength(0);
    const heading = getNodesNamed(window.editor.state, ['ATXHeading2'])[0];
    expect(heading.node.parent?.name).toBe('Document');
  });

  test.each([
    ['- $$\n  x = 1\n  $$', 'ListItem'],
    ['1. $$\n   x = 1\n   $$', 'ListItem'],
    ['> $$\n> x = 1\n> $$', 'Blockquote'],
    ['> > $$\n> > x = 1\n> > $$', 'Blockquote'],
    ['> - $$\n>   x = 1\n>   $$', 'ListItem'],
  ])('math preserves its container: %s', (source, parent) => {
    editor.setUp(source);
    const nodes = getNodesNamed(window.editor.state, ['BlockMath']);
    expect(nodes).toHaveLength(1);
    expect(nodes[0].from).toBe(source.indexOf('$$'));
    expect(nodes[0].to).toBe(source.length);
    expect(nodes[0].node.parent?.name).toBe(parent);
  });

  test('test adding and removing BlockMath closing delimiter', () => {
    const source = `$$\n\n## Heading\n\n${'x = 1\n'.repeat(100)}`;
    editor.setUp(source);
    expect(parseTypes(window.editor)).not.toContain('BlockMath');

    editor.insertText('$$');
    expect(parseTypes(window.editor)).toContain('BlockMath');
    expect(parseTypes(window.editor)).not.toContain('ATXHeading2');

    window.editor.dispatch({ changes: { from: source.length, to: source.length + 2 } });
    expect(parseTypes(window.editor)).not.toContain('BlockMath');
    expect(parseTypes(window.editor)).toContain('ATXHeading2');
  });

  test('test BlockMath not matched with non-whitespace prefix', () => {
    editor.setUp('x $$\nx = 1\nx $$');
    expect(parseTypes(window.editor)).not.toContain('BlockMath');
  });

  test.each([
    'before\n$$\nafter',
    '> intro\n>\n> $$\n> x = 1\n\n## Outside',
    '- $$\n  x = 1\n\n## Outside',
    '- $$\n  x = 1\n- $$',
    '> $$\n> x = 1\n\n$$',
    '```\n$$\nx = 1\n$$\n```',
    '    $$\n    x = 1\n    $$',
    '$$x = 1\\$$',
  ])('non-math input retains its ordinary Markdown tree: %s', source => {
    const parser = markdownParser.configure(markdownMathExtension);
    expect(parser.parse(source).toString()).toBe(markdownParser.parse(source).toString());
  });

  test.each([
    ['$$x = 1$$', 'x = 1'],
    ['$$\r\nx = 1\r\n$$\r\n', '\r\nx = 1\r\n'],
    ['> $$\n> \\alpha = 1\n> $$', '\n\\alpha = 1\n'],
    ['>$$\n> \\alpha = 1\n>$$', '\n\\alpha = 1\n'],
    ['- $$\n  x = 1\n\n  $$', '\nx = 1\n\n'],
    ['$$\n\\$$\nx = 1\n$$', '\n\\$$\nx = 1\n'],
    ['$$x = 1\\\\$$', 'x = 1\\\\'],
  ])('math content excludes only delimiters and container prefixes: %s', (source, content) => {
    const tree = markdownParser.configure(markdownMathExtension).parse(source);
    const nodes: string[] = [];
    tree.iterate({
      enter: node => {
        if (node.name === 'BlockMath') {
          nodes.push(node.node.getChildren('BlockMathContent')
            .map(child => source.slice(child.from, child.to)).join(''));
        }
      },
    });
    expect(nodes).toEqual([content]);
  });

  test('unmatched math keeps a quoted list in one container', () => {
    const source = '> - $$x\n> - $$x\n> \n> - $$x\n> - $$x\n> $$x';
    const tree = markdownParser.configure(markdownMathExtension).parse(source);
    const expected = markdownParser.parse(source);
    const ranges = (parsed: typeof tree) => {
      const nodes: [string, number, number][] = [];
      parsed.iterate({
        enter: node => {
          nodes.push([node.name, node.from, node.to]);
        },
      });
      return nodes;
    };

    expect(tree.toString()).toBe(expected.toString());
    expect(ranges(tree)).toEqual(ranges(expected));
    expect(tree.topNode.getChildren('Blockquote')).toHaveLength(1);
    expect(tree.topNode.firstChild?.getChildren('BulletList')).toHaveLength(1);
  });

  test('incremental math parsing agrees with a fresh parse', () => {
    const parser = markdownParser.configure(markdownMathExtension);
    let source = `# First\n\n${'paragraph\n\n'.repeat(100)}$$\n\n${'x = 1\n'.repeat(100)}`;
    let tree = parser.parse(source);
    const edit = (from: number, to: number, insert: string) => {
      const fragments = TreeFragment.applyChanges(TreeFragment.addTree(tree), [
        { fromA: from, toA: to, fromB: from, toB: from + insert.length },
      ]);
      source = source.slice(0, from) + insert + source.slice(to);
      tree = parser.parse(source, fragments);
      expect(tree.toString()).toBe(parser.parse(source).toString());
    };

    edit(source.length, source.length, '$$');
    edit(0, 0, 'introduction\n\n');
    edit(source.length - 1, source.length, '');
    edit(source.length, source.length, '$');
    edit(source.indexOf('$$'), source.indexOf('$$') + 1, '');
  });

  test('math retries preserve stopped parses', () => {
    const source = '> $$\n\n# First\n\ntext\n\n# Second\n\nmore text';
    const trees = [markdownParser, markdownParser.configure(markdownMathExtension)].map(parser => {
      const partial = parser.startParse(source);
      partial.stopAt(source.indexOf('# Second'));
      let tree = partial.advance();
      while (tree === null) {
        tree = partial.advance();
      }
      return tree.toString();
    });
    expect(trees[1]).toBe(trees[0]);
  });

  test('interleaved math parses keep independent retry state', () => {
    const parser = markdownParser.configure(markdownMathExtension);
    const sources = ['> $$\n\n# Heading', '$$x = 1$$', '- $$\n\n# Heading'];
    const parses = sources.map(source => parser.startParse(source));
    const results = parses.map(() => '');
    for (let step = 0; step < 100 && results.some(result => result === ''); step++) {
      parses.forEach((partial, index) => {
        if (results[index] !== '') {
          return;
        }
        const tree = partial.advance();
        if (tree !== null) {
          results[index] = tree.toString();
        }
      });
    }
    expect(results).toEqual(sources.map(source => parser.parse(source).toString()));
  });

  test('nested Markdown math remains highlighted after an outer retry', () => {
    const inner = markdownParser.configure(markdownMathExtension);
    const parser = markdownParser.configure([markdownMathExtension, parseCode({ codeParser: () => inner })]);
    const source = '> $$\n\n```markdown\n$$x = 1$$\n```';
    const tree = parser.parse(source);
    expect(tree.resolveInner(source.indexOf('1'), 1).name).toBe('number');
  });

  test('batched retries preserve closed math around unmatched containers', () => {
    const source = '$$before = 1$$\n\n> $$x\n\n$$after = 2$$\n\n> $$y\n\n# Heading';
    const tree = markdownParser.configure(markdownMathExtension).parse(source);
    const blocks = tree.topNode.getChildren('BlockMath');

    expect(blocks.map(node => source.slice(node.from, node.to))).toEqual(['$$before = 1$$', '$$after = 2$$']);
    expect(tree.resolveInner(source.indexOf('1'), 1).name).toBe('number');
    expect(tree.resolveInner(source.indexOf('2'), 1).name).toBe('number');
    expect(tree.topNode.lastChild?.name).toBe('ATXHeading1');
  });

  test('later passes discover nested unmatched openings', () => {
    const source = '$$outer\n> $$inner\n> - $$item\n\n# Heading';
    const tree = markdownParser.configure(markdownMathExtension).parse(source);
    expect(tree.toString()).toBe(markdownParser.parse(source).toString());
  });

  test.each([100, 4000])('repeated unmatched blocks use two passes: %s', count => {
    const source = '> $$\n\n'.repeat(count);
    let reads = 0;
    let passes = 0;
    const input = {
      length: source.length,
      lineChunks: false,
      chunk(from: number) { reads++; return source.slice(from); },
      read(from: number, to: number) { reads++; return source.slice(from, to); },
    };
    const tree = markdownParser.configure([markdownMathExtension, {
      wrap: inner => {
        passes++;
        return inner;
      },
    }]).parse(input);
    expect(tree.toString()).toBe(markdownParser.parse(source).toString());
    expect(passes).toBe(2);
    expect(reads).toBeLessThan(count * 15);
  });
});

describe('Math previews', () => {
  test.each([
    '$$\nx = 1\n$$',
    '> $$\n> x = 1\n> $$',
    '> - $$\n>   x = 1\n>   $$',
  ])('math previews use clean TeX content: %s', source => {
    editor.setUp('', previewMath);
    editor.setText(source);
    const button = window.editor.dom.querySelector<HTMLElement>('.cm-md-previewButton');
    expect(button?.dataset.code).toBe('\nx = 1\n');
  });

  test.each(['$$\n\n## Heading', '$$$$', '> $$\n>\n> $$'])('empty or unclosed math has no preview: %s', source => {
    editor.setUp(source, previewMath);
    expect(window.editor.dom.querySelector('.cm-md-previewButton')).toBeNull();
  });
});

function parseTypes(editor: EditorView) {
  const types: string[] = [];
  syntaxTree(editor.state).iterate({
    enter: node => {
      types.push(node.type.name);
    },
  });

  return types;
}
