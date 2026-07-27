import {LanguageDescription} from "@codemirror/language"

export const languages = [
  LanguageDescription.of({
    name: "HTML",
    alias: ["xhtml"],
    extensions: ["html", "htm", "handlebars", "hbs"],
    load() {
      return import("@codemirror/lang-html").then(m => m.html())
    }
  }),
  LanguageDescription.of({
    name: "Markdown",
    extensions: ["md", "markdown", "mkd"],
    load() {
      return import("../lang-markdown").then(m => m.markdown())
    }
  }),
]
