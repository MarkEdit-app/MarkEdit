# MarkEdit-app/lang-html

This package is a trimmed [@codemirror/lang-html](https://code.haverbeke.berlin/codemirror/lang-html), containing only what lang-markdown consumes.

The upstream package embeds the JavaScript and CSS grammars to parse `<script>`, `<style>`, `style="..."` and `on*="..."` contents, which isn't worth the size for HTML inside Markdown. Everything else, including tag completion and auto closing, is kept as is.

Check "[MarkEdit]" to see the actual modified behavior.

This directory is derived from [@codemirror/lang-html](https://code.haverbeke.berlin/codemirror/lang-html) and is released under the [MIT license](https://code.haverbeke.berlin/codemirror/lang-html/src/branch/main/LICENSE).
