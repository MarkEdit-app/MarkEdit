import { EditorView } from '@codemirror/view';
import { Language, languageDataProp, syntaxHighlighting } from '@codemirror/language';
import { markdownLanguage } from '@codemirror/lang-markdown';
import { Tag, tagHighlighter } from '@lezer/highlight';
import type { StyleSpec } from 'style-mod';
import { tags } from './builder';
import { nestedMarkdownTags as nestedTags } from './markdownTags';

interface ColorRole {
  name: `syntax-${string}` | `markdown-${string}`;
  tags: readonly Tag[];
}

// General roles precede more specific roles, which win when both are customized
const syntaxRoles: readonly ColorRole[] = [
  { name: 'syntax-name', tags: [tags.name] },
  { name: 'syntax-literal', tags: [tags.literal] },
  { name: 'syntax-meta', tags: [tags.meta] },
  { name: 'syntax-comment', tags: [tags.comment] },
  { name: 'syntax-keyword', tags: [tags.keyword, tags.modifier] },
  { name: 'syntax-operator', tags: [tags.operator, tags.operatorKeyword] },
  { name: 'syntax-punctuation', tags: [tags.punctuation] },
  { name: 'syntax-string', tags: [tags.string] },
  { name: 'syntax-string-special', tags: [tags.special(tags.string)] },
  { name: 'syntax-regular-expression', tags: [tags.regexp] },
  { name: 'syntax-escape', tags: [tags.escape] },
  { name: 'syntax-atom', tags: [tags.atom] },
  { name: 'syntax-boolean', tags: [tags.bool] },
  { name: 'syntax-number', tags: [tags.number] },
  { name: 'syntax-variable', tags: [tags.variableName] },
  { name: 'syntax-property', tags: [tags.propertyName] },
  { name: 'syntax-type', tags: [tags.typeName, tags.namespace] },
  { name: 'syntax-class', tags: [tags.className] },
  { name: 'syntax-attribute', tags: [tags.attributeName, tags.annotation] },
  { name: 'syntax-tag', tags: [tags.tagName] },
  { name: 'syntax-label', tags: [tags.labelName] },
  { name: 'syntax-constant', tags: [tags.color, tags.constant(tags.name), tags.standard(tags.name)] },
  { name: 'syntax-function', tags: [tags.function(tags.variableName), tags.function(tags.propertyName)] },
  { name: 'syntax-macro', tags: [tags.macroName, tags.special(tags.variableName)] },
  { name: 'syntax-inserted', tags: [tags.inserted] },
  { name: 'syntax-deleted', tags: [tags.deleted] },
  { name: 'syntax-changed', tags: [tags.changed] },
  { name: 'syntax-invalid', tags: [tags.invalid] },
];

const markdownRoles: readonly ColorRole[] = [
  { name: 'markdown-quote', tags: [tags.quote] },
  { name: 'markdown-bold', tags: [tags.strong] },
  { name: 'markdown-italic', tags: [tags.emphasis] },
  { name: 'markdown-strikethrough', tags: [tags.strikethrough] },
  { name: 'markdown-link', tags: [tags.link, tags.url] },
  { name: 'markdown-inline-code', tags: [tags.inlineCode, nestedTags.InlineCode] },
  { name: 'markdown-divider', tags: [tags.contentSeparator] },
  { name: 'markdown-code-info', tags: [tags.codeInfo, nestedTags.CodeInfo] },
  // Delimiters may also carry formatting tags; their explicit colors take precedence
  { name: 'markdown-marker', tags: [tags.processingInstruction, tags.listMark, tags.quoteMark, tags.linkMark, tags.codeMark] },
  { name: 'markdown-list-marker', tags: [tags.listMark, nestedTags.ListMark] },
  { name: 'markdown-table-marker', tags: [tags.tableMark, nestedTags.TableDelimiter] },
  { name: 'markdown-quote-marker', tags: [tags.quoteMark, nestedTags.QuoteMark] },
  { name: 'markdown-link-marker', tags: [tags.linkMark, nestedTags.LinkMark] },
  { name: 'markdown-code-marker', tags: [tags.codeMark, nestedTags.CodeMark] },
];

function highlighter(roles: readonly ColorRole[], scope?: Language) {
  const matchers = roles.map(role => tagHighlighter([{ tag: role.tags, class: `cm-markedit-${role.name}` }]));
  const cache = new WeakMap<Tag, string>();

  return syntaxHighlighting({
    scope: scope === undefined ? undefined : node => node.prop(languageDataProp) === scope.data,
    style(inputTags) {
      return inputTags.map(tag => {
        let classes = cache.get(tag);
        if (classes === undefined) {
          // Match the actual tag: an ancestor's cached roles can lose combined modifiers
          classes = matchers.map(matcher => matcher.style([tag])).filter(Boolean).join(' ');
          cache.set(tag, classes);
        }

        return classes;
      }).filter(Boolean).join(' ') || null;
    },
  });
}

const styles: Record<string, StyleSpec> = {};
for (const role of [...syntaxRoles, ...markdownRoles]) {
  for (const property of ['color', 'text-shadow']) {
    const variable = `--markedit-${role.name}-${property}`;

    // An absent variable must add no declaration, not an "inherit" override
    styles[`@container style(${variable})`] = {
      [`.cm-content .cm-markedit-${role.name}`]: {
        [property]: `var(${variable})`,
      },
    };
  }
}

export const semanticHighlighting = [
  highlighter(syntaxRoles),
  highlighter(markdownRoles, markdownLanguage),
  EditorView.theme(styles),
];
