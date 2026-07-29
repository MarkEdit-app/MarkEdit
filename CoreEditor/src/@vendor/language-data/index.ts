import {LanguageDescription} from "@codemirror/language"

export const languages = [
  LanguageDescription.of({
    name: "Markdown",
    extensions: ["md", "markdown", "mkd"],
    load() {
      return import("../lang-markdown").then(m => m.markdown())
    }
  }),
]
