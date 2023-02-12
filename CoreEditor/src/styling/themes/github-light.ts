import { EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';
import { lightBase as base } from './colors';

const colors = {
  accent: '#0550ae',
  text: '#24292f',
  comment: '#6e7781',
  activeLine: '#eaeef27f',
  searchMatch: '#fae17d7f',
  selectedMatch: '#bf8700',
  selectionHighlight: '#4ac26b50',
  visibleSpace: '#afb8c1',
  lighterBackground: '#afb8c133',
};

function theme() {
  return buildTheme({
    text: colors.text,
    comment: colors.comment,
    background: '#ffffff',
    caret: '#0a69da',
    selection: '#add6ff',
    activeLine: colors.activeLine,
    matchingBracket: '#cee9d6',
    lineNumber: '#8c959f',
    searchMatch: colors.searchMatch,
    selectedMatch: colors.selectedMatch,
    selectionHighlight: colors.selectionHighlight,
    visibleSpace: colors.visibleSpace,
    lighterBackground: colors.lighterBackground,
    bracketBorder: '#83d296',
  });
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.keyword, tags.modifier, tags.operator, tags.operatorKeyword], color: '#cf222e' },
    { tag: [tags.literal, tags.inserted, tags.tagName], color: base.green },
    { tag: [tags.deleted, tags.macroName], color: base.red },
    { tag: [tags.className, tags.definition(tags.propertyName), tags.definition(tags.typeName), tags.listMark], color: '#953800' },
    { tag: [tags.function(tags.variableName), tags.function(tags.propertyName)], color: '#8250df' },
    { tag: [tags.meta, tags.comment], color: colors.comment },
    { tag: [tags.link, tags.escape, tags.string, tags.regexp, tags.special(tags.string)], color: '#0a3069' },
    { tag: [tags.url, tags.linkMark], color: colors.text },
    { tag: tags.propertyName, color: colors.text },
    { tag: [tags.quote, tags.quoteMark], color: base.green, fontStyle: 'italic' },
  ]);
}

export default function GitHubLight(): EditorTheme {
  return {
    accentColor: colors.accent,
    extension: [theme(), highlight()],
  };
}

export { colors };
