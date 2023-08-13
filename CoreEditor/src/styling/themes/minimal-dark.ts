import { EditorColors, EditorTheme } from '../types';
import { buildTheme, buildHighlight, tags } from '../builder';
import { lightBase as light, darkBase as dark } from './colors';
import { colors as fallback } from './github-dark';

const palette = {
  accent: '#ffffff',
};

const colors: EditorColors = {
  accent: palette.accent,
  text: light.gray4,
  comment: light.gray1,
  background: '#000000',
  caret: palette.accent,
  lineNumber: dark.gray1,
  matchingBracket: dark.gray3,
  selection: dark.gray5,
  activeLine: fallback.activeLine,
  searchMatch: fallback.searchMatch,
  selectionHighlight: fallback.selectionHighlight,
  visibleSpace: fallback.visibleSpace,
  lighterBackground: fallback.lighterBackground,
};

function theme() {
  return buildTheme(colors, 'dark');
}

function highlight() {
  // Order matters, don't change it unless you fully understand how it works
  return buildHighlight(colors, [
    { tag: [tags.link, tags.escape, tags.string, tags.inserted, tags.regexp, tags.listMark, tags.special(tags.string)], color: colors.accent },
    { tag: [tags.linkMark, tags.quoteMark], color: colors.accent },
    { tag: [tags.className, tags.attributeName, tags.definition(tags.typeName), tags.function(tags.variableName)], color: colors.accent },
    { tag: [tags.contentSeparator, tags.definition(tags.variableName), tags.function(tags.propertyName)], color: colors.accent },
    { tag: [tags.meta, tags.comment], color: light.gray1, fontStyle: 'italic' },
    { tag: [tags.url, tags.tagName, tags.codeInfo], color: light.gray3 },
    { tag: tags.strong, color: colors.accent, fontWeight: 'bold' },
    { tag: tags.emphasis, color: colors.accent, fontStyle: 'italic' },
  ], 'dark');
}

export default function MinimalDark(): EditorTheme {
  return {
    colors,
    extension: [theme(), highlight()],
  };
}
