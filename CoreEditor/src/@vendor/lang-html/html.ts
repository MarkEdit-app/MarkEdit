import {parser} from "@lezer/html"
import {EditorView} from "@codemirror/view"
import {EditorSelection} from "@codemirror/state"
import {LRLanguage, indentNodeProp, foldNodeProp, LanguageSupport, syntaxTree,
        bracketMatchingHandle} from "@codemirror/language"
import {elementName, htmlCompletionSourceWith, type TagSpec} from "./complete"
export {htmlCompletionSource, type TagSpec, htmlCompletionSourceWith} from "./complete"

const htmlPlain = LRLanguage.define({
  name: "html",
  parser: parser.configure({
    props: [
      indentNodeProp.add({
        Element(context) {
          let after = /^(\s*)(<\/)?/.exec(context.textAfter)!
          if (context.node.to <= context.pos + after[0].length) return context.continue()
          return context.lineIndent(context.node.from) + (after[2] ? 0 : context.unit)
        },
        "OpenTag CloseTag SelfClosingTag"(context) {
          return context.column(context.node.from) + context.unit
        },
        Document(context) {
          if (context.pos + /\s*/.exec(context.textAfter)![0].length < context.node.to)
            return context.continue()
          let endElt = null, close
          for (let cur = context.node;;) {
            let last = cur.lastChild
            if (!last || last.name != "Element" || last.to != cur.to) break
            endElt = cur = last
          }
          if (endElt && !((close = endElt.lastChild) && (close.name == "CloseTag" || close.name == "SelfClosingTag")))
            return context.lineIndent(endElt.from) + context.unit
          return null
        }
      }),
      foldNodeProp.add({
        Element(node) {
          let first = node.firstChild, last = node.lastChild!
          if (!first || first.name != "OpenTag") return null
          return {from: first.to, to: last.name == "CloseTag" ? last.from : node.to}
        }
      }),
      bracketMatchingHandle.add({
        "OpenTag CloseTag": node => node.getChild("TagName")
      })
    ]
  }),
  languageData: {
    commentTokens: {block: {open: "<!--", close: "-->"}},
    indentOnInput: /^\s*<\/\w+\W$/,
    wordChars: "-_"
  }
})

/// A language provider based on the [Lezer HTML
/// parser](https://code.haverbeke.berlin/lezer/html).
// [MarkEdit] upstream wraps the parser with the JavaScript and CSS grammars, we don't bundle them.
export const htmlLanguage = htmlPlain

/// Language support for HTML, including
/// [`htmlCompletion`](#lang-html.htmlCompletion).
export function html(config: {
  /// By default, the syntax tree will highlight mismatched closing
  /// tags. Set this to `false` to turn that off (for example when you
  /// expect to only be parsing a fragment of HTML text, not a full
  /// document).
  matchClosingTags?: boolean,
  /// By default, the parser does not allow arbitrary self-closing tags.
  /// Set this to `true` to turn on support for `/>` self-closing tag
  /// syntax.
  selfClosingTags?: boolean,
  /// Determines whether [`autoCloseTags`](#lang-html.autoCloseTags)
  /// is included in the support extensions. Defaults to true.
  autoCloseTags?: boolean,
  /// Add additional tags that can be completed.
  extraTags?: Record<string, TagSpec>,
  /// Add additional completable attributes to all tags.
  extraGlobalAttributes?: Record<string, null | readonly string[]>
} = {}) {
  let dialect = ""
  if (config.matchClosingTags === false) dialect = "noMatch"
  if (config.selfClosingTags === true) dialect = (dialect ? dialect + " " : "") + "selfClosing"
  let lang = dialect ? htmlLanguage.configure({dialect}) : htmlLanguage
  return new LanguageSupport(lang, [
    htmlLanguage.data.of({autocomplete: htmlCompletionSourceWith(config)}),
    config.autoCloseTags !== false ? autoCloseTags : []
  ])
}

const selfClosers = new Set(
  "area base br col command embed frame hr img input keygen link meta param source track wbr menuitem".split(" "))

/// Extension that will automatically insert close tags when a `>` or
/// `/` is typed.
export const autoCloseTags = EditorView.inputHandler.of((view, from, to, text, insertTransaction) => {
  if (view.composing || view.state.readOnly || from != to || (text != ">" && text != "/") ||
      !htmlLanguage.isActiveAt(view.state, from, -1)) return false
  let base = insertTransaction(), {state} = base
  let closeTags = state.changeByRange(range => {
    let didType = state.doc.sliceString(range.from - 1, range.to) == text
    let {head} = range, after = syntaxTree(state).resolveInner(head, -1), name
    if (didType && text == ">" && after.name == "EndTag") {
      let tag = after.parent!
      if (tag.parent?.lastChild?.name != "CloseTag" &&
          (name = elementName(state.doc, tag.parent, head)) &&
          !selfClosers.has(name)) {
        let to = head + (state.doc.sliceString(head, head + 1) === ">" ? 1 : 0)
        let insert = `</${name}>`
        return {range, changes: {from: head, to, insert}}
      }
    } else if (didType && text == "/" && after.name == "IncompleteCloseTag") {
      let tag = after.parent!
      if (after.from == head - 2 && tag.lastChild?.name != "CloseTag" &&
          (name = elementName(state.doc, tag, head)) && !selfClosers.has(name)) {
        let to = head + (state.doc.sliceString(head, head + 1) === ">" ? 1 : 0)
        let insert = `${name}>`
        return {
          range: EditorSelection.cursor(head + insert.length, -1),
          changes: {from: head, to, insert}
        }
      }
    }
    return {range}
  })
  if (closeTags.changes.empty) return false
  view.dispatch([
    base,
    state.update(closeTags, {
      userEvent: "input.complete",
      scrollIntoView: true
    })
  ])
  return true
})
