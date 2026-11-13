import { ChangeSpec, countColumn, EditorSelection, EditorState, Line } from '@codemirror/state';
import { EditorView } from '@codemirror/view';
import { forceParsing, indentUnit, syntaxTree, syntaxTreeAvailable } from '@codemirror/language';
import { SyntaxNode } from '@lezer/common';
import { renumberList } from '../../@vendor/lang-markdown/commands';
import { playSystemBeep } from '../../common/utils';

type ListItem = {
  node: SyntaxNode;
  mark: SyntaxNode;
  marker: string;
  column: number;
  contentColumn: number;
  quoteDepth: number;
};

/**
 * Move sibling list items by one structural level, keeping their content attached.
 * Mixed selections and items without a destination use the normal indentation commands.
 * Unsafe structural moves are handled without edits, so callers do not fall back.
 */
export function indentList(editor: EditorView, direction: 1 | -1): boolean {
  if (editor.state.readOnly || editor.state.selection.ranges.length !== 1) {
    return false;
  }

  if (!parseForIndentation(editor)) {
    return true;
  }

  const { state } = editor;
  const { from, to } = state.selection.main;
  const firstItem = itemAt(state, from);
  const sourceList = firstItem?.node.parent;
  if (!firstItem || !sourceList) {
    return false;
  }

  const previousNode = previousListItem(firstItem.node.prevSibling);
  const parentNode = sourceList.parent;
  const destinationNode = direction === 1 ? previousNode
    : parentNode?.name === 'ListItem' ? parentNode
      : firstItem.quoteDepth > 0 ? sourceList.getChild('ListItem') : null;
  const targetItem = destinationNode && readItem(state, destinationNode);
  if (!targetItem || (direction === -1 && parentNode?.name !== 'ListItem' && firstItem.column <= targetItem.column)) {
    return false;
  }

  // A partial tree can truncate both an item's content and its following siblings
  if (!parseForIndentation(editor, state.doc.length)) {
    return true;
  }

  if (editor.state !== state) {
    return indentList(editor, direction);
  }

  const selectionEnd = to > from && state.doc.lineAt(to).from === to ? to - 1 : to;
  let lastItemNode = from === to ? firstItem.node : syntaxTree(state).resolve(selectionEnd, -1);
  while (lastItemNode.parent && !sameNode(lastItemNode.parent, sourceList)) {
    lastItemNode = lastItemNode.parent;
  }

  if (lastItemNode.name !== 'ListItem' || !lastItemNode.parent || !sameNode(lastItemNode.parent, sourceList)) {
    return false;
  }

  const selectedItems = readSiblings(state, firstItem.node, lastItemNode.from);
  if (!selectedItems) {
    return false;
  }

  const lastItem = selectedItems[selectedItems.length - 1];
  const changes: ChangeSpec[] = [];

  if (direction === 1) {
    const childItem = lastChildItem(state, targetItem, sourceList.name);
    const startNumber = childItem && /^\d/.test(childItem.marker) ? parseInt(childItem.marker) + 1 : 1;
    const { isConsecutive } = moveItems(
      state, changes, selectedItems,
      childItem?.column ?? targetItem.contentColumn,
      childItem?.marker ?? firstItem.marker, startNumber,
    );

    if (isConsecutive && !renumberFollowing(state, changes, lastItem, -selectedItems.length - 1)) {
      return false;
    }
  } else if (parentNode?.name !== 'ListItem') {
    // A tab after ">" can visually indent a sibling without creating a nested list
    for (const item of selectedItems) {
      changeItem(state, changes, item, targetItem.column, item.marker);
    }
  } else {
    const trailingItems = readSiblings(state, lastItem.node.nextSibling);
    if (!trailingItems) {
      return false;
    }

    const startNumber = /^\d/.test(targetItem.marker) ? parseInt(targetItem.marker) + 1 : 1;
    const { lastMarker } = moveItems(state, changes, selectedItems, targetItem.column, targetItem.marker, startNumber);

    // Following children become children of the lifted item without reordering text
    const childItem = lastChildItem(state, lastItem, sourceList.name);
    const matchingChild = childItem?.marker.slice(-1) === lastItem.marker.slice(-1) ? childItem : undefined;
    const contentShift = targetItem.column - lastItem.column + lastMarker.length - lastItem.marker.length;
    const contentColumn = (matchingChild?.column ?? lastItem.contentColumn) + contentShift;
    const nextNumber = matchingChild && /^\d/.test(matchingChild.marker) ? parseInt(matchingChild.marker) + 1 : 1;

    moveItems(state, changes, trailingItems, contentColumn, lastItem.marker, nextNumber);
    if (!renumberFollowing(state, changes, targetItem, parseInt(lastMarker) - parseInt(targetItem.marker) - 1)) {
      return false;
    }
  }

  const changeSet = state.changes(changes);
  const invalidMarkers: string[] = [];
  changeSet.iterChanges((_from, _to, _fromB, _toB, inserted) => {
    // Changes contain only markers and whitespace, which CodeMirror may combine.
    if (/^\s*\d{10,}[.)]\s*$/.test(inserted.toString())) {
      invalidMarkers.push(inserted.toString());
    }
  });

  if (invalidMarkers.length > 0) {
    playSystemBeep('Ordered-list numbers cannot exceed nine digits');
    return true;
  }

  const { anchor, head } = state.selection.main;
  editor.dispatch(state.update({
    changes: changeSet,
    selection: EditorSelection.range(changeSet.mapPos(anchor, 1), changeSet.mapPos(head, 1)),
    scrollIntoView: true,
    userEvent: direction === 1 ? 'input.indent' : 'delete.dedent',
  }));

  return true;
}

export function parseForIndentation(editor: EditorView, upto = editor.state.doc.lineAt(editor.state.selection.main.from).to): boolean {
  const { state } = editor;
  if ((syntaxTreeAvailable(state, upto) && syntaxTree(state).length >= upto) || forceParsing(editor, upto, 50)) {
    return true;
  }

  playSystemBeep('List indentation requires a complete parse');
  return false;
}

function moveItems(state: EditorState, changes: ChangeSpec[], items: ListItem[], targetColumn: number, marker: string, startNumber: number) {
  let lastMarker = marker;
  let previousNumber = NaN;
  let isConsecutive = true;

  for (const [index, item] of items.entries()) {
    const originalNumber = parseInt(item.marker);
    if (index > 0 && !Number.isNaN(originalNumber) && originalNumber !== previousNumber + 1) {
      isConsecutive = false;
    }

    const number = isConsecutive ? startNumber + index : originalNumber;
    lastMarker = /^\d/.test(marker) ? `${number}${marker.slice(-1)}` : marker;
    changeItem(state, changes, item, targetColumn, lastMarker);
    previousNumber = originalNumber;
  }

  return { lastMarker, isConsecutive };
}

function renumberFollowing(state: EditorState, changes: ChangeSpec[], afterItem: ListItem, offset: number) {
  const numberChanges: ChangeSpec[] = [];
  if (/^\d/.test(afterItem.marker)) {
    renumberList(afterItem.node, state.doc, numberChanges, offset);
  }

  let isValid = true;
  state.changes(numberChanges).iterChanges((from, _to, _fromB, _toB, inserted) => {
    const item = itemAt(state, from);
    if (item) {
      changeItem(state, changes, item, item.column, inserted.toString() + item.marker.slice(-1));
    } else {
      isValid = false;
    }
  });

  return isValid;
}

function sameNode(a: SyntaxNode, b: SyntaxNode) {
  return a.name === b.name && a.from === b.from && a.to === b.to;
}

function previousListItem(node: SyntaxNode | null): SyntaxNode | null {
  while (node && node.name !== 'ListItem') {
    node = node.prevSibling;
  }

  return node;
}

function readSiblings(state: EditorState, startNode: SyntaxNode | null, endPosition = Infinity) {
  const items: ListItem[] = [];
  for (let node = startNode; node && node.from <= endPosition; node = node.nextSibling) {
    if (node.name === 'ListItem') {
      const item = readItem(state, node);
      if (!item) {
        return undefined;
      }

      items.push(item);
    }
  }

  return items;
}

function lastChildItem(state: EditorState, item: ListItem, listName: string) {
  const childList = item.node.lastChild;
  const node = childList?.name === listName ? previousListItem(childList.lastChild) : null;
  return node && readItem(state, node);
}

function changeItem(state: EditorState, changes: ChangeSpec[], item: ListItem, targetColumn: number, marker: string) {
  const firstLine = state.doc.lineAt(item.node.from);
  const lastLine = state.doc.lineAt(item.node.to);
  for (let lineNumber = firstLine.number; lineNumber <= lastLine.number; lineNumber++) {
    const line = state.doc.line(lineNumber);
    const marks: SyntaxNode[] = [];

    let contentBoundary = line.to;
    syntaxTree(state).iterate({
      from: line.from, to: line.to,
      enter(node) {
        if (node.name === 'CodeText' && node.to > line.from) {
          contentBoundary = Math.min(contentBoundary, Math.max(line.from, node.from));
        } else if (node.name === 'ListMark' || node.name === 'QuoteMark') {
          marks.push(node.node);
        }
      },
    });

    const indentDelta = targetColumn - item.column + (lineNumber === firstLine.number ? 0 : marker.length - item.marker.length);
    const change = shiftIndent(state, line, item.quoteDepth, indentDelta, contentBoundary);
    if (change) {
      changes.push(change);
    }

    const actualIndentDelta = change
      ? countColumn(line.text.slice(0, change.from - line.from) + change.insert, 4) - countColumn(line.text.slice(0, change.to - line.from), 4)
      : 0;
    const markerColumnDelta = actualIndentDelta + (lineNumber === firstLine.number ? marker.length - item.marker.length : 0);

    // Both indentation and marker padding stop before the parser's code payload boundary
    if (markerColumnDelta % 4 !== 0 && line.text.includes('\t')) {
      let quoteDepth = 0;
      for (const node of marks) {
        if (node.name === 'QuoteMark' && ++quoteDepth <= item.quoteDepth) {
          continue;
        }

        if (node.to >= contentBoundary) {
          continue;
        }

        const space = leadingSpace(state.doc.sliceString(node.to, contentBoundary));
        if (space.includes('\t')) {
          const prefix = state.doc.sliceString(line.from, node.to);
          const padding = countColumn(prefix + space, 4) - countColumn(prefix, 4);
          changes.push({ from: node.to, to: node.to + space.length, insert: ' '.repeat(padding) });
        }
      }
    }
  }

  if (marker !== item.marker) {
    changes.push({ from: item.mark.from, to: item.mark.to, insert: marker });
  }
}

function itemAt(state: EditorState, position: number): ListItem | undefined {
  const line = state.doc.lineAt(position);
  const markerStart = line.from + line.text.search(/[^ \t>]/);
  const cursor = Math.max(position, markerStart);

  for (const side of [-1, 1] as const) {
    for (let node: SyntaxNode | null = syntaxTree(state).resolve(cursor, side); node; node = node.parent) {
      if (node.name === 'FencedCode' || node.name === 'CodeBlock') {
        return undefined;
      }

      if (node.name === 'ListItem' && state.doc.lineAt(node.from).number === line.number) {
        return readItem(state, node);
      }
    }
  }

  return undefined;
}

function readItem(state: EditorState, node: SyntaxNode): ListItem | undefined {
  const mark = node.getChild('ListMark');
  if (!mark) {
    return undefined;
  }

  const line = state.doc.lineAt(mark.from);
  const prefix = state.doc.sliceString(line.from, mark.from);
  if (!/^[ \t>]*$/.test(prefix)) {
    return undefined;
  }

  const marker = state.doc.sliceString(mark.from, mark.to);
  const absoluteColumn = countColumn(prefix, 4);
  const quoteDepth = prefix.split('>').length - 1;
  const quoteBaseColumn = quotePrefix(line.text, quoteDepth)?.column ?? 0;
  const column = absoluteColumn - quoteBaseColumn;
  const markerEnd = absoluteColumn + marker.length;
  const space = leadingSpace(state.doc.sliceString(mark.to, line.to));
  const padding = countColumn(prefix + marker + space, 4) - markerEnd;
  return {
    node, mark, marker, column,
    contentColumn: column + marker.length + (padding >= 1 && padding <= 4 ? padding : 1),
    quoteDepth,
  };
}

function shiftIndent(state: EditorState, line: Line, quoteDepth: number, indentDelta: number, contentBoundary: number) {
  if (indentDelta === 0 || (contentBoundary === line.to && line.text.trim().length === 0)) {
    return undefined;
  }

  const quote = quotePrefix(line.text, quoteDepth);
  if (!quote) {
    return undefined;
  }

  const indentStart = quote.end;
  const originalWhitespace = leadingSpace(line.text.slice(indentStart, Math.max(indentStart, contentBoundary - line.from)));
  const indentEnd = indentStart + originalWhitespace.length;
  const originalColumn = countColumn(line.text.slice(0, indentEnd), 4);
  const targetIndentWidth = Math.max(0, originalColumn - quote.column + indentDelta);

  let outputColumn = countColumn(line.text.slice(0, indentStart), 4);
  const quotePadding = quoteDepth > 0 && (targetIndentWidth > 0 || originalWhitespace.length > 0) ? 1 : 0;
  const targetColumn = outputColumn + quotePadding + targetIndentWidth;

  let insert = ' '.repeat(quotePadding);
  outputColumn += quotePadding;

  while (outputColumn < targetColumn) {
    const nextTabColumn = outputColumn + 4 - outputColumn % 4;
    if (state.facet(indentUnit) === '\t' && nextTabColumn <= targetColumn) {
      insert += '\t';
      outputColumn = nextTabColumn;
    } else {
      insert += ' ';
      outputColumn++;
    }
  }

  return insert === originalWhitespace ? undefined : { from: line.from + indentStart, to: line.from + indentEnd, insert };
}

function quotePrefix(text: string, depth: number) {
  let end = 0;
  for (let index = 0; index < depth; index++) {
    const mark = /^[ \t]*>/.exec(text.slice(end));
    if (!mark) {
      return undefined;
    }

    end += mark[0].length;
  }

  const padding = depth > 0 && /[ \t]/.test(text.charAt(end)) ? 1 : 0;
  return { end, column: countColumn(text.slice(0, end), 4) + padding };
}

function leadingSpace(text: string) {
  const end = text.search(/[^ \t]/);
  return end < 0 ? text : text.slice(0, end);
}
