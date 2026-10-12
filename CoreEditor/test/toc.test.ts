import { EditorSelection, EditorState, StateEffect } from '@codemirror/state';
import { describe, expect, test } from '@jest/globals';
import { sleep } from './utils/helpers';
import * as editor from './utils/editor';
import * as toc from '../src/modules/toc';

describe('Table of contents module', () => {
  test('document outline uses live text and full parsed heading titles', async() => {
    const title = 'A long heading '.repeat(6) + 'searchable tail';
    const text = ['# ' + title, '', '```md', '# Not a heading', '```', '', 'Résumé 📄', '---'].join('\r\n');
    editor.setUp(text);
    await sleep(200);

    const outline = toc.getDocumentOutline();
    expect(outline).toEqual({
      revision: expect.any(String),
      text: window.editor.state.sliceDoc(),
      headings: toc.getTableOfContents(false),
    });

    expect(outline.headings).toMatchObject([
      { title, level: 1, lineNumber: 1 },
      { title: 'Résumé 📄', level: 2, lineNumber: 7 },
    ]);

    expect(toc.getTableOfContents()[0].title).toBe(title.substring(0, 64) + '...');
    window.editor.dispatch({ changes: { from: 0, insert: '\n' } });
    expect(toc.getDocumentOutline().headings.map(heading => heading.lineNumber)).toEqual([2, 8]);
  });

  test('outline text can be reused until text or line endings change', () => {
    editor.setUp('# Plan\r\nBody', EditorState.lineSeparator.of('\r\n'));
    const snapshot = toc.getDocumentOutline();
    expect(snapshot.text).toBe('# Plan\r\nBody');
    expect(toc.getDocumentOutline(snapshot.revision).text).toBeUndefined();

    window.editor.dispatch({ selection: EditorSelection.cursor(2) });
    expect(toc.getDocumentOutline(snapshot.revision).revision).toBe(snapshot.revision);
    expect(toc.getDocumentOutline(snapshot.revision).text).toBeUndefined();

    window.editor.dispatch({ changes: { from: 2, to: 6, insert: 'Next' } });
    const edited = toc.getDocumentOutline(snapshot.revision);
    expect(edited.revision).not.toBe(snapshot.revision);
    expect(edited.text).toBe('# Next\r\nBody');
    expect(toc.getDocumentOutline(edited.revision).text).toBeUndefined();

    window.editor.dispatch({ effects: StateEffect.reconfigure.of(EditorState.lineSeparator.of('\r')) });
    const changedLineEndings = toc.getDocumentOutline(edited.revision);
    expect(changedLineEndings.revision).not.toBe(edited.revision);
    expect(changedLineEndings.text).toBe('# Next\rBody');

    editor.setUp('Replacement document');
    expect(toc.getDocumentOutline(changedLineEndings.revision).text).toBe('Replacement document');
  });

  test('unchanged large documents are omitted from the serialized outline', () => {
    editor.setUp('body '.repeat(400_000));
    const snapshot = toc.getDocumentOutline();
    expect(snapshot.text?.length).toBe(2_000_000);

    const outline = toc.getDocumentOutline(snapshot.revision);
    expect(outline.revision).toBe(snapshot.revision);
    expect(outline.text).toBeUndefined();
    expect(JSON.stringify(outline)).not.toContain('"text"');
    expect(JSON.stringify(outline).length).toBeLessThan(128);
  });

  test('test getting table of contents', async() => {
    editor.setUp('## Hello\n\n- One\n- Two\n- Three\n\n### MarkEdit\n\nHave fun.');
    await sleep(200);
    const results = toc.getTableOfContents();

    expect(results[0].level).toBe(2);
    expect(results[0].title).toBe('Hello');
    expect(results[1].level).toBe(3);
    expect(results[1].title).toBe('MarkEdit');
  });

  test('test Setext heading level 1 (===)', async() => {
    editor.setUp('This is title\n=============');
    await sleep(200);
    const results = toc.getTableOfContents();

    expect(results.length).toBe(1);
    expect(results[0].level).toBe(1);
    expect(results[0].title).toBe('This is title');
  });

  test('test Setext heading level 2 (---)', async() => {
    editor.setUp('This is title\n-------------');
    await sleep(200);
    const results = toc.getTableOfContents();

    expect(results.length).toBe(1);
    expect(results[0].level).toBe(2);
    expect(results[0].title).toBe('This is title');
  });

  test('test mixed ATX and Setext headings', async() => {
    editor.setUp('# ATX Level 1\n\nSetext Level 1\n==============\n\n## ATX Level 2\n\nSetext Level 2\n--------------');
    await sleep(200);
    const results = toc.getTableOfContents();

    expect(results.length).toBe(4);
    expect(results[0].level).toBe(1);
    expect(results[0].title).toBe('ATX Level 1');
    expect(results[1].level).toBe(1);
    expect(results[1].title).toBe('Setext Level 1');
    expect(results[2].level).toBe(2);
    expect(results[2].title).toBe('ATX Level 2');
    expect(results[3].level).toBe(2);
    expect(results[3].title).toBe('Setext Level 2');
  });

  test('test edge case - title with leading/trailing whitespace', async() => {
    editor.setUp('  Title with spaces  \n===================');
    await sleep(200);
    const results = toc.getTableOfContents();

    expect(results.length).toBe(1);
    expect(results[0].level).toBe(1);
    expect(results[0].title).toBe('Title with spaces');
  });

  test('selecting previous section first moves to the current heading', async() => {
    const text = '# First\n\nFirst body\n\n# Last\n\nLast body';
    editor.setUp(text);
    await sleep(200);
    window.editor.dispatch({
      selection: EditorSelection.cursor(text.indexOf('Last body')),
    });

    toc.selectPreviousSection();
    expect(window.editor.state.selection.main.head).toBe(text.indexOf('# Last'));

    toc.selectPreviousSection();
    expect(window.editor.state.selection.main.head).toBe(text.indexOf('# First'));
  });
});
