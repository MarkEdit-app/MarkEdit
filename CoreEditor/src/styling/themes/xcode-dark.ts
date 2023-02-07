import { EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';
import { darkBase as base } from './colors';

const colors = {
  accent: '#5dd8ff',
  text: '#ffffffd9',
  brown: '#bf8555',
};

function theme() {
  return buildTheme({
    text: colors.text,
    background: '#1f1f24',
    caret: colors.text,
    selection: '#515b70',
    activeLine: '#23252b',
    matchingBracket: '#67b7a440',
    lineNumber: '#747478',
    searchMatch: '#545558',
    selectedMatch: '#fffb00',
    selectionHighlight: '#4d5465',
    visibleSpace: '#424d5b',
    lighterBackground: '#424d5b40',
  }, 'dark');
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.keyword, tags.modifier, tags.operator, tags.operatorKeyword, tags.self], color: '#fc5fa3' },
    { tag: [tags.literal, tags.inserted], color: base.green },
    { tag: [tags.deleted, tags.macroName], color: base.red },
    { tag: [tags.className, tags.definition(tags.propertyName), tags.definition(tags.typeName)], color: '#9ef1dd' },
    { tag: [tags.function(tags.variableName), tags.function(tags.propertyName)], color: '#a167e6' },
    { tag: [tags.meta, tags.comment], color: '#6c7986' },
    { tag: [tags.link, tags.escape, tags.string, tags.regexp, tags.special(tags.string)], color: '#fc6a5d' },
    { tag: [tags.linkMark, tags.listMark], color: '#fd8f3f' },
    { tag: tags.url, color: '#41a1c0' },
    { tag: tags.propertyName, color: colors.text },
    { tag: tags.tagName, color: colors.accent },
    { tag: tags.attributeName, color: colors.brown },
    { tag: tags.definition(tags.variableName), color: '#67b7a4' },
    { tag: [tags.quote, tags.quoteMark], color: '#92a1b1', fontStyle: 'italic' },
    { tag: [tags.atom, tags.bool, tags.number], color: '#d0bf69' },
    { tag: tags.emphasis, color: colors.brown, fontStyle: 'italic' },
    { tag: tags.strong, color: '#d0a8ff', fontWeight: 'bold' },
  ], 'dark');
}

export default function XcodeDark(): EditorTheme {
  return {
    accentColor: colors.accent,
    extension: [theme(), highlight()],
  };
}
