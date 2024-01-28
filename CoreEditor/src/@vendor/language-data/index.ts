import {LanguageSupport, LanguageDescription, StreamParser, StreamLanguage} from "@codemirror/language"

function legacy(parser: StreamParser<unknown>): LanguageSupport {
  return new LanguageSupport(StreamLanguage.define(parser))
}

function sql(dialectName: keyof typeof import("@codemirror/lang-sql")) {
  return import("@codemirror/lang-sql").then(m => m.sql({dialect: (m as any)[dialectName]}))
}

/// An array of language descriptions for known language packages.
export const languages = [
  // New-style language modes
  LanguageDescription.of({
    name: "C",
    extensions: ["c","h","ino"],
    load() {
      return import("@codemirror/lang-cpp").then(m => m.cpp())
    }
  }),
  LanguageDescription.of({
    name: "C++",
    alias: ["cpp"],
    extensions: ["cpp","c++","cc","cxx","hpp","h++","hh","hxx"],
    load() {
      return import("@codemirror/lang-cpp").then(m => m.cpp())
    }
  }),
  LanguageDescription.of({
    name: "CQL",
    alias: ["cassandra"],
    extensions: ["cql"],
    load() { return sql("Cassandra") }
  }),
  LanguageDescription.of({
    name: "CSS",
    extensions: ["css"],
    load() {
      return import("@codemirror/lang-css").then(m => m.css())
    }
  }),
  LanguageDescription.of({
    name: "HTML",
    alias: ["xhtml"],
    extensions: ["html", "htm", "handlebars", "hbs"],
    load() {
      return import("@codemirror/lang-html").then(m => m.html())
    }
  }),
  LanguageDescription.of({
    name: "Java",
    extensions: ["java"],
    load() {
      return import("@codemirror/lang-java").then(m => m.java())
    }
  }),
  LanguageDescription.of({
    name: "JavaScript",
    alias: ["ecmascript","js","node"],
    extensions: ["js", "mjs", "cjs"],
    load() {
      return import("@codemirror/lang-javascript").then(m => m.javascript())
    }
  }),
  LanguageDescription.of({
    name: "JSON",
    alias: ["json5"],
    extensions: ["json","map"],
    load() {
      return import("@codemirror/lang-json").then(m => m.json())
    }
  }),
  LanguageDescription.of({
    name: "JSX",
    extensions: ["jsx"],
    load() {
      return import("@codemirror/lang-javascript").then(m => m.javascript({jsx: true}))
    }
  }),
  LanguageDescription.of({
    name: "MariaDB SQL",
    load() { return sql("MariaSQL") }
  }),
  LanguageDescription.of({
    name: "Markdown",
    extensions: ["md", "markdown", "mkd"],
    load() {
      return import("../lang-markdown").then(m => m.markdown())
    }
  }),
  LanguageDescription.of({
    name: "MS SQL",
    load() { return sql("MSSQL") }
  }),
  LanguageDescription.of({
    name: "MySQL",
    load() { return sql("MySQL") }
  }),
  LanguageDescription.of({
    name: "PHP",
    extensions: ["php", "php3", "php4", "php5", "php7", "phtml"],
    load() {
      return import("@codemirror/lang-php").then(m => m.php())
    }
  }),
  LanguageDescription.of({
    name: "PLSQL",
    extensions: ["pls"],
    load() { return sql("PLSQL") }
  }),
  LanguageDescription.of({
    name: "PostgreSQL",
    load() { return sql("PostgreSQL") }
  }),
  LanguageDescription.of({
    name: "Python",
    extensions: ["BUILD","bzl","py","pyw"],
    filename: /^(BUCK|BUILD)$/,
    load() {
      return import("@codemirror/lang-python").then(m => m.python())
    }
  }),
  LanguageDescription.of({
    name: "Rust",
    extensions: ["rs"],
    load() {
      return import("@codemirror/lang-rust").then(m => m.rust())
    }
  }),
  LanguageDescription.of({
    name: "SQL",
    extensions: ["sql"],
    load() { return sql("StandardSQL") }
  }),
  LanguageDescription.of({
    name: "SQLite",
    load() { return sql("SQLite") }
  }),
  LanguageDescription.of({
    name: "TSX",
    extensions: ["tsx"],
    load() {
      return import("@codemirror/lang-javascript").then(m => m.javascript({jsx: true, typescript: true}))
    }
  }),
  LanguageDescription.of({
    name: "TypeScript",
    alias: ["ts"],
    extensions: ["ts"],
    load() {
      return import("@codemirror/lang-javascript").then(m => m.javascript({typescript: true}))
    }
  }),
  LanguageDescription.of({
    name: "WebAssembly",
    extensions: ["wat","wast"],
    load() {
      return import("@codemirror/lang-wast").then(m => m.wast())
    }
  }),
  LanguageDescription.of({
    name: "XML",
    alias: ["rss","wsdl","xsd"],
    extensions: ["xml","xsl","xsd","svg"],
    load() {
      return import("@codemirror/lang-xml").then(m => m.xml())
    }
  }),
  LanguageDescription.of({
    name: "YAML",
    alias: ["yml"],
    extensions: ["yaml","yml"],
    load() {
      return import("@codemirror/lang-yaml").then(m => m.yaml())
    }
  }),

  // Legacy modes ported from CodeMirror 5

  LanguageDescription.of({
    name: "C#",
    alias: ["csharp","cs"],
    extensions: ["cs"],
    load() {
      return import("@codemirror/legacy-modes/mode/clike").then(m => legacy(m.csharp))
    }
  }),
  LanguageDescription.of({
    name: "CMake",
    extensions: ["cmake","cmake.in"],
    filename: /^CMakeLists\.txt$/,
    load() {
      return import("@codemirror/legacy-modes/mode/cmake").then(m => legacy(m.cmake))
    }
  }),
  LanguageDescription.of({
    name: "Common Lisp",
    alias: ["lisp"],
    extensions: ["cl","lisp","el"],
    load() {
      return import("@codemirror/legacy-modes/mode/commonlisp").then(m => legacy(m.commonLisp))
    }
  }),
  LanguageDescription.of({
    name: "Dart",
    extensions: ["dart"],
    load() {
      return import("@codemirror/legacy-modes/mode/clike").then(m => legacy(m.dart))
    }
  }),
  LanguageDescription.of({
    name: "diff",
    extensions: ["diff","patch"],
    load() {
      return import("@codemirror/legacy-modes/mode/diff").then(m => legacy(m.diff))
    }
  }),
  LanguageDescription.of({
    name: "Dockerfile",
    filename: /^Dockerfile$/,
    load() {
      return import("@codemirror/legacy-modes/mode/dockerfile").then(m => legacy(m.dockerFile))
    }
  }),
  LanguageDescription.of({
    name: "F#",
    alias: ["fsharp"],
    extensions: ["fs", "fsx"],
    load() {
      return import("@codemirror/legacy-modes/mode/mllike").then(m => legacy(m.fSharp))
    }
  }),
  LanguageDescription.of({
    name: "Go",
    extensions: ["go"],
    load() {
      return import("@codemirror/legacy-modes/mode/go").then(m => legacy(m.go))
    }
  }),
  LanguageDescription.of({
    name: "Groovy",
    extensions: ["groovy","gradle"],
    filename: /^Jenkinsfile$/,
    load() {
      return import("@codemirror/legacy-modes/mode/groovy").then(m => legacy(m.groovy))
    }
  }),
  LanguageDescription.of({
    name: "Haskell",
    extensions: ["hs"],
    load() {
      return import("@codemirror/legacy-modes/mode/haskell").then(m => legacy(m.haskell))
    }
  }),
  LanguageDescription.of({
    name: "HTTP",
    load() {
      return import("@codemirror/legacy-modes/mode/http").then(m => legacy(m.http))
    }
  }),
  LanguageDescription.of({
    name: "Julia",
    extensions: ["jl"],
    load() {
      return import("@codemirror/legacy-modes/mode/julia").then(m => legacy(m.julia))
    }
  }),
  LanguageDescription.of({
    name: "Kotlin",
    extensions: ["kt", "kts"],
    load() {
      return import("@codemirror/legacy-modes/mode/clike").then(m => legacy(m.kotlin))
    }
  }),
  LanguageDescription.of({
    name: "LESS",
    extensions: ["less"],
    load() {
      return import("@codemirror/legacy-modes/mode/css").then(m => legacy(m.less))
    }
  }),
  LanguageDescription.of({
    name: "Lua",
    extensions: ["lua"],
    load() {
      return import("@codemirror/legacy-modes/mode/lua").then(m => legacy(m.lua))
    }
  }),
  LanguageDescription.of({
    name: "Mathematica",
    extensions: ["m","nb","wl","wls"],
    load() {
      return import("@codemirror/legacy-modes/mode/mathematica").then(m => legacy(m.mathematica))
    }
  }),
  LanguageDescription.of({
    name: "Nginx",
    filename: /nginx.*\.conf$/i,
    load() {
      return import("@codemirror/legacy-modes/mode/nginx").then(m => legacy(m.nginx))
    }
  }),
  LanguageDescription.of({
    name: "Objective-C",
    alias: ["objective-c","objc"],
    extensions: ["m"],
    load() {
      return import("@codemirror/legacy-modes/mode/clike").then(m => legacy(m.objectiveC))
    }
  }),
  LanguageDescription.of({
    name: "Objective-C++",
    alias: ["objective-c++","objc++"],
    extensions: ["mm"],
    load() {
      return import("@codemirror/legacy-modes/mode/clike").then(m => legacy(m.objectiveCpp))
    }
  }),
  LanguageDescription.of({
    name: "OCaml",
    alias: ["ocaml"],
    extensions: ["ml","mli","mll","mly"],
    load() {
      return import("@codemirror/legacy-modes/mode/mllike").then(m => legacy(m.oCaml))
    }
  }),
  LanguageDescription.of({
    name: "Pascal",
    extensions: ["p","pas"],
    load() {
      return import("@codemirror/legacy-modes/mode/pascal").then(m => legacy(m.pascal))
    }
  }),
  LanguageDescription.of({
    name: "Perl",
    extensions: ["pl","pm"],
    load() {
      return import("@codemirror/legacy-modes/mode/perl").then(m => legacy(m.perl))
    }
  }),
  LanguageDescription.of({
    name: "PowerShell",
    extensions: ["ps1","psd1","psm1"],
    load() {
      return import("@codemirror/legacy-modes/mode/powershell").then(m => legacy(m.powerShell))
    }
  }),
  LanguageDescription.of({
    name: "R",
    alias: ["rscript"],
    extensions: ["r","R"],
    load() {
      return import("@codemirror/legacy-modes/mode/r").then(m => legacy(m.r))
    }
  }),
  LanguageDescription.of({
    name: "Ruby",
    alias: ["jruby","macruby","rake","rb","rbx"],
    extensions: ["rb"],
    filename: /^(Gemfile|Rakefile)$/,
    load() {
      return import("@codemirror/legacy-modes/mode/ruby").then(m => legacy(m.ruby))
    }
  }),
  LanguageDescription.of({
    name: "Scala",
    extensions: ["scala"],
    load() {
      return import("@codemirror/legacy-modes/mode/clike").then(m => legacy(m.scala))
    }
  }),
  LanguageDescription.of({
    name: "Scheme",
    extensions: ["scm","ss"],
    load() {
      return import("@codemirror/legacy-modes/mode/scheme").then(m => legacy(m.scheme))
    }
  }),
  LanguageDescription.of({
    name: "SCSS",
    extensions: ["scss"],
    load() {
      return import("@codemirror/legacy-modes/mode/css").then(m => legacy(m.sCSS))
    }
  }),
  LanguageDescription.of({
    name: "Shell",
    alias: ["bash","sh","zsh"],
    extensions: ["sh","ksh","bash"],
    filename: /^PKGBUILD$/,
    load() {
      return import("@codemirror/legacy-modes/mode/shell").then(m => legacy(m.shell))
    }
  }),
  LanguageDescription.of({
    name: "Swift",
    extensions: ["swift"],
    load() {
      return import("@codemirror/legacy-modes/mode/swift").then(m => legacy(m.swift))
    }
  }),
  LanguageDescription.of({
    name: "sTeX",
    load() {
      return import("@codemirror/legacy-modes/mode/stex").then(m => legacy(m.stex))
    }
  }),
  LanguageDescription.of({
    name: "LaTeX",
    alias: ["tex"],
    extensions: ["text","ltx","tex"],
    load() {
      return import("@codemirror/legacy-modes/mode/stex").then(m => legacy(m.stex))
    }
  }),
  LanguageDescription.of({
    name: "TOML",
    extensions: ["toml"],
    load() {
      return import("@codemirror/legacy-modes/mode/toml").then(m => legacy(m.toml))
    }
  }),
]
