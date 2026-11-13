import { afterEach, describe, expect, jest, test } from '@jest/globals';
import { EditorSelection, EditorState } from '@codemirror/state';
import { forceParsing, indentUnit, syntaxTree } from '@codemirror/language';
import { history, undo, redo } from '../src/@vendor/commands/history';
import { insertNewlineContinueMarkup, markdown } from '@codemirror/lang-markdown';
import { indentationKeymap } from '../src/modules/indentation';
import { TabKeyBehavior } from '../src/modules/indentation/types';
import { performEditCommand } from '../src/modules/commands';
import { EditCommand } from '../src/modules/commands/types';

import * as language from '@codemirror/language';
import * as editor from './utils/editor';
import * as utils from '../src/common/utils';

jest.mock('@codemirror/language', () => ({
  ...jest.requireActual<typeof import('@codemirror/language')>('@codemirror/language'),
  __esModule: true,
}));

afterEach(() => {
  jest.restoreAllMocks();
  window.editor.destroy();
});

function codePayload(state: EditorState) {
  const content: string[] = [];
  syntaxTree(state).iterate({
    enter(node) {
      if (node.name === 'CodeText') {
        content.push(state.sliceDoc(node.from, node.to));
      }
    },
  });

  return content.join('');
}

function codeStructure(state: EditorState) {
  const blocks: { type: string; owners: string[] }[] = [];
  syntaxTree(state).iterate({
    enter(node) {
      if (node.name !== 'FencedCode' && node.name !== 'CodeBlock') {
        return;
      }

      const owners: string[] = [];
      for (let parent = node.node.parent; parent; parent = parent.parent) {
        if (parent.name === 'ListItem') {
          const paragraph = parent.getChild('Paragraph');
          const owner = paragraph && state.sliceDoc(paragraph.from, paragraph.to);
          if (typeof owner === 'string' && owner !== '' && owner !== 'Parent') {
            owners.push(owner);
          }
        }
      }

      blocks.push({ type: node.name, owners });
    },
  });

  return blocks;
}

function run(input: string, key = 'Tab', unit = '  ') {
  const cursor = input.indexOf('|');
  editor.setUp(input.replace('|', ''), [indentUnit.of(unit), history()]);
  window.config.tabKeyBehavior = TabKeyBehavior.insertTab as CodeGen_Int;

  editor.selectRange(cursor, cursor);
  expect(indentationKeymap.find(binding => binding.key === key)?.run?.(window.editor)).toBe(true);
  const { state } = window.editor;
  return state.sliceDoc(0, state.selection.main.head) + '|' + state.sliceDoc(state.selection.main.head);
}

describe('list indentation', () => {
  test('waits for a complete parse and then moves all content and siblings', () => {
    const input = '1. Parent\n   1. Child\n      continuation\n2. Next\n3. Last';
    editor.setUp(input);
    editor.selectRange(input.indexOf('Child'), input.indexOf('Child'));

    const originalState = window.editor.state;
    const partialTree = markdown().language.parser.parse(input.slice(0, input.indexOf('\n      continuation')));
    const tree = jest.spyOn(language, 'syntaxTree').mockReturnValue(partialTree);
    const parse = jest.spyOn(language, 'forceParsing').mockReturnValueOnce(false);
    const beep = jest.spyOn(utils, 'playSystemBeep').mockImplementation(() => {});

    expect(indentationKeymap[1].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe(input);
    expect(window.editor.state.selection.eq(originalState.selection)).toBe(true);
    expect(parse).toHaveBeenCalledTimes(1);
    expect(parse.mock.calls[0]?.[1]).toBe(input.length);
    expect(parse.mock.calls[0]?.[2]).toBe(50);
    expect(beep).toHaveBeenCalledTimes(1);

    parse.mockImplementationOnce(() => {
      tree.mockRestore();
      window.editor.dispatch({});
      return true;
    });

    expect(indentationKeymap[1].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe('1. Parent\n2. Child\n   continuation\n3. Next\n4. Last');
    expect(beep).toHaveBeenCalledTimes(1);
  });

  test.each(['Mod-]', 'Tab'])('parses the selected line before choosing how to indent with %s', key => {
    const input = '1. Parent\n2. Child\n   continuation\n3. Next';
    editor.setUp(input);
    editor.selectRange(input.indexOf('Child'), input.indexOf('Child'));

    const selection = window.editor.state.selection;
    const lineEnd = window.editor.state.doc.lineAt(selection.main.from).to;
    const partialTree = markdown().language.parser.parse('1. Parent');
    const tree = jest.spyOn(language, 'syntaxTree').mockReturnValue(partialTree);
    const parse = jest.spyOn(language, 'forceParsing').mockReturnValueOnce(false);
    const beep = jest.spyOn(utils, 'playSystemBeep').mockImplementation(() => {});
    const command = indentationKeymap.find(binding => binding.key === key)?.run;

    expect(command?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe(input);
    expect(window.editor.state.selection.eq(selection)).toBe(true);
    expect(parse).toHaveBeenCalledTimes(1);
    expect(parse.mock.calls[0]?.[1]).toBe(lineEnd);
    expect(parse.mock.calls[0]?.[2]).toBe(50);
    expect(beep).toHaveBeenCalledTimes(1);

    parse.mockImplementationOnce(() => {
      tree.mockRestore();
      window.editor.dispatch({});
      return true;
    });

    expect(command?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe('1. Parent\n   1. Child\n      continuation\n2. Next');
    expect(beep).toHaveBeenCalledTimes(1);
  });

  test('rejects an overflowing ordered-list number without changing text or selection', () => {
    const input = '999999999. Parent\n           1. Child\n              continuation';
    editor.setUp(input);
    editor.selectRange(input.indexOf('Child'), input.indexOf('Child'));

    const selection = window.editor.state.selection;
    const beep = jest.spyOn(utils, 'playSystemBeep').mockImplementation(() => {});
    expect(indentationKeymap[1].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe(input);
    expect(window.editor.state.selection.eq(selection)).toBe(true);
    expect(beep).toHaveBeenCalledTimes(1);
  });

  test.each([
    ['1. Parent\n|2. Child', 'Tab', '1. Parent\n   |1. Child'],
    ['1. Parent\n   |1. Child', 'Shift-Tab', '1. Parent\n|2. Child'],
  ])('keeps the caret before the moved marker: %s', (input, key, output) => {
    expect(run(input, key)).toBe(output);
  });

  test.each([
    ['- Parent\n- |Child\n- Next', '- Parent\n  - |Child\n- Next'],
    ['1. Parent\n2. |Child\n3. Next', '1. Parent\n   1. |Child\n2. Next'],
    ['10. Parent\n11. |Child\n12. Next', '10. Parent\n    1. |Child\n11. Next'],
    ['1) Parent\n2) |Child\n3) Next', '1) Parent\n   1) |Child\n2) Next'],
    ['1.   Parent\n2. |Child', '1.   Parent\n     1. |Child'],
    ['- [ ] Parent\n- |[x] Child', '- [ ] Parent\n  - |[x] Child'],
    ['> 1. Parent\n> 2. |Child\n> 3. Next', '> 1. Parent\n>    1. |Child\n> 2. Next'],
    ['>- Parent\n>- |Child', '>- Parent\n>   - |Child'],
    ['>>- Parent\n> >- |Child', '>>- Parent\n> >   - |Child'],
    ['1. Parent\n   1. Existing\n2. |Child\n3. Next', '1. Parent\n   1. Existing\n   2. |Child\n2. Next'],
    ['1. Parent\n1. |Child\n1. Next', '1. Parent\n   1. |Child\n1. Next'],
    ['1. Parent\n2. |Child\n7. Next\n8. Last', '1. Parent\n   1. |Child\n7. Next\n8. Last'],
    ['1. Parent\n2. |', '1. Parent\n   1. |'],
  ])('nests items using their parent alignment: %s', (input, output) => {
    expect(run(input)).toBe(output);
    let node = syntaxTree(window.editor.state).resolveInner(window.editor.state.selection.main.head, -1);
    while (node.name !== 'ListItem' && node.parent) {
      node = node.parent;
    }

    expect(node.parent?.parent?.name).toBe('ListItem');
  });

  test.each([
    ['1. Parent\n   1. |Child\n2. Next', '1. Parent\n2. |Child\n3. Next'],
    ['> 1. Parent\n>    1. |Child\n> 2. Next', '> 1. Parent\n> 2. |Child\n> 3. Next'],
    ['1. Parent\n   1. First\n   2. |Child\n   3. Last\n2. Next', '1. Parent\n   1. First\n2. |Child\n   1. Last\n3. Next'],
    ['9. Parent\n   1. |Child\n   2. Last\n10. Next', '9. Parent\n10. |Child\n    1. Last\n11. Next'],
    ['- Parent\n  1. |Child\n  2. Last\n- Next', '- Parent\n- |Child\n  1. Last\n- Next'],
    ['1. Parent\n   - |Child\n2. Next', '1. Parent\n2. |Child\n3. Next'],
    ['1. Parent\n   1. |', '1. Parent\n2. |'],
    ['1. Parent\n   1. First\n   7. |Child\n   9. Last\n   10. Last2\n2. Next', '1. Parent\n   1. First\n2. |Child\n   1. Last\n   2. Last2\n3. Next'],
    ['1. Parent\n   1. |Child\n      1. Grandchild\n   2. Last\n2. Next', '1. Parent\n2. |Child\n   1. Grandchild\n   2. Last\n3. Next'],
    ['> - Parent\n>\t- |Child', '> - Parent\n> - |Child'],
    ['> - Parent\n>\t  - |Child', '> - Parent\n> - |Child'],
  ])('outdents to the parent level: %s', (input, output) => {
    expect(run(input, 'Shift-Tab')).toBe(output);
  });

  test('moves continuation lines and descendants, adjusting for marker width', () => {
    const input = '10. Parent\n11. |Child\n    continuation\n\n    - Grandchild\n12. Next';
    const output = '10. Parent\n    1. |Child\n       continuation\n\n       - Grandchild\n11. Next';
    expect(run(input)).toBe(output);
    expect(indentationKeymap[1].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe(input.replace('|', ''));
  });

  test('keeps content attached when renumbering crosses a digit boundary', () => {
    expect(run('8. Parent\n9. |Child\n10. Next\n    - Grandchild'))
      .toBe('8. Parent\n   1. |Child\n9. Next\n   - Grandchild');
  });

  test('preserves tab padding alignment when moving and renumbering', () => {
    expect(run('9. Parent\n10.\t|Child\n\tcontinuation'))
      .toBe('9. Parent\n   1. |Child\n      continuation');
  });

  test.each([
    ['    1.\tGrandchild\n        - Descendant', '   1.  Grandchild\n       - Descendant', '1.  Grandchild'],
    ['    >\t1. Grandchild\n    >      - Descendant', '   >   1. Grandchild\n   >      - Descendant', '1. Grandchild'],
  ])('preserves nested content when renumbering changes tab alignment: %s', (input, output, grandchild) => {
    expect(run(`8. Parent\n9. |Child\n10. Next\n${input}`))
      .toBe(`8. Parent\n   1. |Child\n9. Next\n${output}`);
    let node = syntaxTree(window.editor.state).resolveInner(editor.getText().indexOf('Descendant'), 1);
    const parents: string[] = [];
    for (; node.parent; node = node.parent) {
      if (node.name === 'ListItem') {
        parents.push(window.editor.state.sliceDoc(node.from, window.editor.state.doc.lineAt(node.from).to).trimStart());
      }
    }

    expect(parents).toEqual(['- Descendant', grandchild, '9. Next']);
  });

  test('does not decrement following numbering across a selected restart', () => {
    editor.setUp('1. Parent\n2. A\n3. B\n1. C\n2. Next');
    editor.selectRange(editor.getText().indexOf('2. A'), editor.getText().indexOf('2. Next'));
    expect(indentationKeymap[0].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe('1. Parent\n   1. A\n   2. B\n   1. C\n2. Next');
  });

  test.each([
    { parent: 1, numbers: [1, 2, 1], expected: [2, 3, 1] },
    { parent: 1, numbers: [1, 4, 5], expected: [2, 4, 5] },
    { parent: 1, numbers: [1, 1, 1], expected: [2, 1, 1] },
  ])('continues after the last emitted number when outdenting: %j', ({ parent, numbers, expected }) => {
    const items = (values: number[]) => values.map((number, index) => `${number}. ${'ABC'[index]}`);
    editor.setUp(`${parent}. Parent\n${items(numbers).map(line => '   ' + line).join('\n')}\n${parent + 1}. Next`, history());
    editor.selectRange(editor.getText().indexOf('1. A'), editor.getText().indexOf(`${parent + 1}. Next`));

    const originalState = window.editor.state;
    expect(indentationKeymap[1].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe(`${parent}. Parent\n${items(expected).join('\n')}\n${expected[2] + 1}. Next`);
    expect(undo(window.editor)).toBe(true);
    expect(editor.getText()).toBe(originalState.doc.toString());
    expect(window.editor.state.selection.eq(originalState.selection)).toBe(true);
  });

  test.each([
    { name: 'fenced payload, including blank lines', block: '```\n\tcode\n\t\n  \tmore\n```', owner: 'Next', unit: '  ' },
    { name: 'fenced payload inside a quote', block: '> ```\n> \tcode\n> \tmore\n> ```', owner: 'Next', unit: '  ' },
    { name: 'indented payload inside a quote', block: '>\n>     \tcode\n>     \tmore', owner: 'Next', unit: '  ' },
    { name: 'nested code moving with its item', block: '- Nested\n  ```\n  1.\tcode\n  \tmore\n  ```', owner: 'Child', unit: '\t' },
  ])('preserves code bytes and ownership: $name', ({ block, owner, unit }) => {
    const code = '\n' + block.split('\n').map(line => (owner === 'Child' ? '   ' : '    ') + line).join('\n');
    const input = `8. Parent\n9. Child${owner === 'Child' ? code : ''}\n10. Next${owner === 'Next' ? code : ''}`;
    editor.setUp(input, indentUnit.of(unit));
    editor.selectRange(input.indexOf('Child'), input.indexOf('Child'));

    const payload = codePayload(window.editor.state);
    const structure = codeStructure(window.editor.state);
    expect(payload).toContain('\t');
    expect(structure).toHaveLength(1);
    expect(structure[0].owners).toContain(owner);
    expect(indentationKeymap[0].run?.(window.editor)).toBe(true);
    expect(codePayload(window.editor.state)).toBe(payload);
    expect(codeStructure(window.editor.state)).toEqual(structure);
    expect(indentationKeymap[1].run?.(window.editor)).toBe(true);
    expect(codePayload(window.editor.state)).toBe(payload);
    expect(codeStructure(window.editor.state)).toEqual(structure);
  });

  test('uses Markdown tab stops when tabs are preferred', () => {
    expect(run('10. Parent\n11. |Child', 'Tab', '\t')).toBe('10. Parent\n\t1. |Child');
    expect(indentationKeymap[1].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe('10. Parent\n11. Child');
  });

  test('keeps quote padding separate from tab indentation', () => {
    expect(run('> 10. Parent\n> 11. |Child', 'Tab', '\t')).toBe('> 10. Parent\n> \t  1. |Child');
    let node = syntaxTree(window.editor.state).resolve(window.editor.state.selection.main.head, -1);
    while (node.parent && node.name !== 'ListItem') {
      node = node.parent;
    }

    expect(node.parent?.parent?.name).toBe('ListItem');
    expect(indentationKeymap[1].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe('> 10. Parent\n> 11. Child');
  });

  test('uses structural indentation even when four-space units are preferred', () => {
    expect(run('1. Parent\n2. |Child', 'Tab', '    ')).toBe('1. Parent\n   1. |Child');
    expect(indentationKeymap[1].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe('1. Parent\n2. Child');
  });

  test.each([false, true])('preserves sibling selection boundaries and direction (backward: %s)', backward => {
    editor.setUp('1. Parent\n2. Child\n3. Child2\n4. Next');
    const from = editor.getText().indexOf('2.');
    const to = editor.getText().indexOf('4.');

    editor.selectRange(backward ? to : from, backward ? from : to);
    expect(indentationKeymap[0].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe('1. Parent\n   1. Child\n   2. Child2\n2. Next');

    const selection = window.editor.state.selection.main;
    expect(selection.from).toBe(editor.getText().indexOf('1. Child'));
    expect(selection.to).toBe(editor.getText().indexOf('2. Next'));
    expect(selection.anchor > selection.head).toBe(backward);
    expect(indentationKeymap[1].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe('1. Parent\n2. Child\n3. Child2\n4. Next');
  });

  test('renumbers selected siblings with extra indentation inside a blockquote', () => {
    const input = '>   1. Parent\n>   2. Child\n>   3. Child2\n>   4. Next';
    editor.setUp(input);
    editor.selectRange(input.indexOf('2.'), input.indexOf('>   4.'));

    expect(indentationKeymap[0].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe('>   1. Parent\n>      1. Child\n>      2. Child2\n>   2. Next');
    expect(indentationKeymap[1].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe(input);
  });

  test.each(['1. Parent\n2. |Child\n3. Next', '1. Parent\n|2. Child\n3. Next'])('undo/redo restores the move and caret: %s', input => {
    run(input);
    const indentedText = editor.getText();
    const indentedCursor = window.editor.state.selection.main.head;
    expect(undo(window.editor)).toBe(true);
    expect(editor.getText()).toBe(input.replace('|', ''));
    expect(window.editor.state.selection.main.head).toBe(input.indexOf('|'));
    expect(redo(window.editor)).toBe(true);
    expect(editor.getText()).toBe(indentedText);
    expect(window.editor.state.selection.main.head).toBe(indentedCursor);
  });

  test('Enter continues numbering after indenting', () => {
    run('1. Parent\n2. |Child\n3. Next');
    const position = editor.getText().indexOf('Child') + 'Child'.length;
    editor.selectRange(position, position);
    expect(insertNewlineContinueMarkup(window.editor)).toBe(true);
    expect(editor.getText()).toBe('1. Parent\n   1. Child\n   2. \n2. Next');
  });

});

describe('indentation edit commands', () => {
  test.each([
    ['1. Parent\n2. Child', '1. Parent\n   1. Child'],
    ['- Parent\n- Child', '- Parent\n  - Child'],
    ['text', '  text'],
  ])('uses list-aware indentation with a generic fallback: %s', (input, output) => {
    editor.setUp(input);
    editor.selectRange(input.length, input.length);
    performEditCommand(EditCommand.indentMore);
    expect(editor.getText()).toBe(output);
    expect(window.editor.state.selection.main.head).toBe(output.length);

    performEditCommand(EditCommand.indentLess);
    expect(editor.getText()).toBe(input);
    expect(window.editor.state.selection.main.head).toBe(input.length);
  });
});

describe('ordinary indentation', () => {
  test.each(['Tab', 'Shift-Tab'])('does not read every sibling when %s has no structural destination', key => {
    editor.setUp(Array.from({ length: 2000 }, (_, index) => `${index + 1}. Item`).join('\n'));
    expect(forceParsing(window.editor, editor.getText().length, 1000)).toBe(true);
    editor.selectRange(0, 0);

    const lineAt = jest.spyOn(window.editor.state.doc, 'lineAt');
    expect(indentationKeymap.find(binding => binding.key === key)?.run?.(window.editor)).toBe(true);
    expect(lineAt.mock.calls.length).toBeLessThan(20);
  });

  test.each([
    ['Mod-]', '1. Parent\n2. Child', '1. Parent\n  2. Child'],
    ['Shift-Tab', '1. Parent\n   1. Child', '1. Parent\n 1. Child'],
  ])('uses generic indentation inside a mounted Markdown fence: %s', (key, content, output) => {
    editor.setUp(`\`\`\`markdown\n${content}\n\`\`\``, markdown({ codeLanguages: () => markdown().language }));
    expect(forceParsing(window.editor, editor.getText().length, 1000)).toBe(true);

    const cursor = editor.getText().indexOf('Child');
    expect(syntaxTree(window.editor.state).resolveInner(cursor, 1).name).toBe('Paragraph');

    editor.selectRange(cursor, cursor);
    expect(indentationKeymap.find(binding => binding.key === key)?.run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe(`\`\`\`markdown\n${output}\n\`\`\``);
  });

  test.each([
    ['text|', 'Tab', 'text\t|'],
    ['  text|', 'Shift-Tab', 'text|'],
    ['1. |First', 'Tab', '  1. |First'],
    ['1. |First', 'Shift-Tab', '1. |First'],
    ['- Parent\n- Text|', 'Tab', '- Parent\n- Text\t|'],
    ['```\n1. Parent\n2. |Code\n```', 'Tab', '```\n1. Parent\n2. \t|Code\n```'],
  ])('preserves non-list-nesting behavior: %s', (input, key, output) => {
    expect(run(input, key)).toBe(output);
  });

  test('preserves multiple-selection indentation behavior', () => {
    editor.setUp('- Parent\n- Child\n- Last', EditorState.allowMultipleSelections.of(true));
    window.editor.dispatch({ selection: EditorSelection.create([EditorSelection.cursor(11), EditorSelection.cursor(19)]) });
    expect(indentationKeymap[0].run?.(window.editor)).toBe(true);
    expect(editor.getText()).toBe('- Parent\n  - Child\n  - Last');
  });
});
