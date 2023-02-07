import { EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';
import { lightBase as light, darkBase as dark } from './colors';
import { colors as fallback } from './github-light';

const colors = {
  accent: '#000000',
  background: '#ffffff',
  text: dark.gray4,
};

function theme() {
  return buildTheme({
    text: colors.text,
    background: colors.background,
    caret: colors.accent,
    lineNumber: light.gray1,
    matchingBracket: light.gray3,
    selection: light.gray5,
    activeLine: fallback.activeLine,
    searchMatch: fallback.searchMatch,
    selectedMatch: fallback.selectedMatch,
    selectionHighlight: fallback.selectionHighlight,
    visibleSpace: fallback.visibleSpace,
    lighterBackground: fallback.lighterBackground,
  });
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.link, tags.escape, tags.string, tags.inserted, tags.regexp, tags.listMark, tags.special(tags.string)], color: colors.accent },
    { tag: [tags.linkMark, tags.quoteMark], color: colors.accent },
    { tag: [tags.className, tags.attributeName, tags.definition(tags.typeName), tags.function(tags.variableName)], color: colors.accent },
    { tag: [tags.contentSeparator, tags.definition(tags.variableName), tags.function(tags.propertyName)], color: colors.accent },
    { tag: tags.strong, color: colors.accent, fontWeight: 'bold' },
    { tag: tags.emphasis, color: colors.accent, fontStyle: 'italic' },
    { tag: [tags.meta, tags.comment], color: dark.gray1 },
    { tag: [tags.url, tags.tagName, tags.codeInfo], color: dark.gray3 },
  ]);
}

export default function MinimalLight(): EditorTheme {
  return {
    accentColor: colors.accent,
    extension: [theme(), highlight()],
  };
}
