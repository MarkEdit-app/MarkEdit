import {Language, defineLanguageFacet, languageDataProp, foldNodeProp, indentNodeProp, foldService,
        syntaxTree, LanguageDescription, ParseContext} from "@codemirror/language"
import {parser as baseParser, MarkdownParser, GFM, Subscript, Superscript, Emoji} from "@lezer/markdown"
import {SyntaxNode, NodeType, NodeProp} from "@lezer/common"

const data = defineLanguageFacet({block: {open: "<!--", close: "-->"}})

const headingProp = new NodeProp<number>()

const commonmark = baseParser.configure({
  props: [
    foldNodeProp.add(type => {
      return !type.is("Block") || type.is("Document") || isHeading(type) != null ? undefined
        : (tree, state) => ({from: state.doc.lineAt(tree.from).to, to: tree.to})
    }),
    headingProp.add(isHeading),
    indentNodeProp.add({
      Document: () => null
    }),
    languageDataProp.add({
      Document: data
    })
  ]
})

function isHeading(type: NodeType) {
  let match = /^(?:ATX|Setext)Heading(\d)$/.exec(type.name)
  return match ? +match[1] : undefined
}

// [MarkEdit] We prefer empty sections to be foldable (original: https://github.com/codemirror/lang-markdown/blob/main/src/markdown.ts#L31)
function findSectionEnd(headerNode: SyntaxNode, level: number) {
  // [MarkEdit] we also only fold ATXHeadings and leave Setext headings alone
  const nodeType = headerNode.type.name
  if (nodeType.startsWith('SetextHeading')) return headerNode.from

  let last = headerNode
  for (;;) {
    let next = last.nextSibling, heading
    if (!next) {
      if (last.parent?.to) return last.parent.to
      break
    }
    if ((heading = isHeading(next.type)) != null && heading <= level) {
      if (next.from) return next.from - 1
      break
    }
    last = next
  }
  return last.to
}

const headerIndent = foldService.of((state, start, end) => {
  for (let node: SyntaxNode | null = syntaxTree(state).resolveInner(end, -1); node; node = node.parent) {
    if (node.from < start) break
    let heading = node.type.prop(headingProp)
    if (heading == null) continue
    let upto = findSectionEnd(node, heading)
    if (upto > end) return {from: end, to: upto}
  }
  return null
})

export function mkLang(parser: MarkdownParser) {
  return new Language(data, parser, [headerIndent], "markdown")
}

/// Language support for strict CommonMark.
export const commonmarkLanguage = mkLang(commonmark)

const extended = commonmark.configure([GFM, Subscript, Superscript, Emoji])

/// Language support for [GFM](https://github.github.com/gfm/) plus
/// subscript, superscript, and emoji syntax.
export const markdownLanguage = mkLang(extended)

export function getCodeParser(
  languages: readonly LanguageDescription[] | ((info: string) => Language | LanguageDescription | null) | undefined,
  defaultLanguage?: Language
) {
  return (info: string) => {
    if (info && languages) {
      let found = null
      // Strip anything after whitespace
      info = /\S*/.exec(info)![0]
      if (typeof languages == "function") found = languages(info)
      else found = LanguageDescription.matchLanguageName(languages, info, true)
      if (found instanceof LanguageDescription)
        return found.support ? found.support.language.parser : ParseContext.getSkippingParser(found.load())
      else if (found)
        return found.parser
    }
    return defaultLanguage ? defaultLanguage.parser : null
  }
}
