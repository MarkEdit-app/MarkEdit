import { EditorSelection, EditorState, StateEffect, StateField, Text, Transaction } from '@codemirror/state';
import { insertBracket } from '@codemirror/autocomplete';
import { invertedEffects } from '../../@vendor/commands/history';

const setConvertedClosingQuote = StateEffect.define<{ pos: number; active: boolean }>({
  map: (value, changes) => ({ ...value, pos: changes.mapPos(value.pos, 1) }),
});

const convertedClosingQuotes = StateField.define<readonly number[]>({
  create: () => [],
  update(positions, transaction) {
    let updated = positions
      .map(pos => transaction.changes.mapPos(pos, 1))
      .filter(pos => transaction.state.sliceDoc(pos, pos + 1) === '”');

    for (const effect of transaction.effects) {
      if (effect.is(setConvertedClosingQuote)) {
        updated = effect.value.active
          ? [...updated.filter(pos => pos !== effect.value.pos), effect.value.pos]
          : updated.filter(pos => pos !== effect.value.pos);
      }
    }

    return updated;
  },
});

export const smartQuotesHandler = [
  convertedClosingQuotes,
  invertedEffects.of(transaction => transaction.effects
    .filter(effect => effect.is(setConvertedClosingQuote))
    .map(effect => setConvertedClosingQuote.of({ ...effect.value, active: !effect.value.active }))),
  EditorState.transactionFilter.of(transaction => convertAutoClosingQuote(transaction) ?? transaction),
];

function convertAutoClosingQuote(transaction: Transaction) {
  if (!window.config.autoCharacterPairs || !window.config.smartQuotesEnabled) {
    return undefined;
  }

  const skipPos = autoClosingQuoteSkipPosition(transaction);
  if (skipPos !== undefined) {
    return [
      transaction,
      {
        changes: { from: skipPos, to: skipPos + 1 },
        selection: EditorSelection.cursor(skipPos + 1),
        sequential: true,
      },
    ];
  }

  const closingPos = autoClosingQuotePosition(transaction);
  if (closingPos === undefined) {
    return undefined;
  }

  return [
    transaction,
    {
      changes: { from: closingPos, to: closingPos + 1, insert: '”' },
      effects: setConvertedClosingQuote.of({ pos: closingPos, active: true }),
      selection: transaction.newSelection,
      sequential: true,
    },
  ];
}

function autoClosingQuotePosition(transaction: Transaction) {
  const state = transaction.startState;
  const selection = state.selection;
  const userEvent = transaction.annotation(Transaction.userEvent);
  if ((userEvent !== undefined && !transaction.isUserEvent('input.type')) || selection.ranges.length !== 1 || !selection.main.empty) {
    return undefined;
  }

  const caretPos = selection.main.head;
  const changes: { from: number; to: number; insert: Text }[] = [];
  transaction.changes.iterChanges((from, to, _fn, _tn, inserted) => {
    changes.push({ from, to, insert: inserted });
  });

  if (changes.length !== 1) {
    return undefined;
  }

  const change = changes[0];
  if (change.from >= caretPos || change.to > caretPos || state.sliceDoc(change.from, change.to) !== '"' || change.insert.toString() !== '“') {
    return undefined;
  }

  const pos = trackedClosingQuotePosition(state, change.to, caretPos);
  return pos === undefined ? undefined : transaction.changes.mapPos(pos);
}

function autoClosingQuoteSkipPosition(transaction: Transaction) {
  const state = transaction.startState;
  const selection = state.selection;
  if (!transaction.isUserEvent('input.type') || selection.ranges.length !== 1 || !selection.main.empty) {
    return undefined;
  }

  const pos = selection.main.head;
  if (state.sliceDoc(pos, pos + 1) !== '”') {
    return undefined;
  }

  if (!state.field(convertedClosingQuotes).includes(pos)) {
    return undefined;
  }

  const changes: { from: number; to: number; insert: Text }[] = [];
  transaction.changes.iterChanges((from, to, _fromNew, _toNew, inserted) => {
    changes.push({ from, to, insert: inserted });
  });

  if (changes.length !== 1) {
    return undefined;
  }

  const change = changes[0];
  if (change.from !== pos || change.to !== pos || change.insert.toString() !== '"') {
    return undefined;
  }

  const probeState = state.update({
    changes: { from: pos, to: pos + 1, insert: '"' },
  }).state;

  return isTrackedClosingQuote(probeState, pos) ? pos : undefined;
}

function trackedClosingQuotePosition(state: EditorState, from: number, to: number) {
  const text = state.sliceDoc(from, to + 1);
  for (let index = text.indexOf('"'); index !== -1; index = text.indexOf('"', index + 1)) {
    const pos = from + index;
    if (isTrackedClosingQuote(state, pos)) {
      return pos;
    }
  }

  return undefined;
}

function isTrackedClosingQuote(state: EditorState, pos: number) {
  const probeState = pos === state.selection.main.head
    ? state
    : state.update({ selection: EditorSelection.cursor(pos) }).state;
  const probe = insertBracket(probeState, '"');
  return probe !== null && isClosingQuoteSkip(probe, pos);
}

function isClosingQuoteSkip(transaction: Transaction, pos: number) {
  const changes: { from: number; to: number; insert: Text }[] = [];
  transaction.changes.iterChanges((from, to, _fromNew, _toNew, inserted) => {
    changes.push({ from, to, insert: inserted });
  });

  if (changes.length !== 1) {
    return false;
  }

  const change = changes[0];
  return change.from === pos && change.to === pos + 1 && change.insert.toString() === '"' && transaction.newSelection.main.head === pos + 1;
}
