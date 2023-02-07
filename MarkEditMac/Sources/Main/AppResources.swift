//
//  AppResources.swift
//  MarkEditMac
//
//  Created by cyan on 12/31/22.
//

import Foundation
import MarkEditCore

// To make localization work, always use String(localized:comment:) directly and add to this file.
//
// Besides, we use xcloc files to do the translation work:
// https://developer.apple.com/documentation/xcode/exporting-localizations
enum Localized {
  enum General {
    static let done = String(localized: "Done", comment: "Button title, confirm an action")
    static let previous = String(localized: "Previous", comment: "Button title, move to the previous item")
    static let next = String(localized: "Next", comment: "Button title, move to the next item")
    static let all = String(localized: "All", comment: "Button title, perform actions to all items")
  }

  enum Editor {
    static let controlCharacter = String(localized: "Control Character", comment: "Phrase used in CodeMirror to indicate control character")
    static let foldedLines = String(localized: "Folded Lines", comment: "Phrase used in CodeMirror to indicate folded lines")
    static let unfoldedLines = String(localized: "Unfolded Lines", comment: "Phrase used in CodeMirror to indicate unfolded lines")
    static let foldedCode = String(localized: "Folded Code", comment: "Phrase used in CodeMirror to indicated folded code")
    static let unfold = String(localized: "Unfold", comment: "Phrase used in CodeMirror to unfold a piece of text")
    static let foldLine = String(localized: "Fold Line", comment: "Phrase used in CodeMirror fold a line")
    static let unfoldLine = String(localized: "Unfold Line", comment: "Phrase used in CodeMirror to unfold a line")
    static let defaultLinkTitle = String(localized: "title", comment: "Default title used for link insertion")
    static let previewButtonTitle = String(localized: "preview", comment: "Button title for code preview")
    static let tableColumnName = String(localized: "Column", comment: "Column name for table creation")
    static let tableItemName = String(localized: "Item", comment: "Item name for table creation")
  }

  enum Toolbar {
    static let tableOfContents = String(localized: "Table of Contents", comment: "Toolbar item to show table of contents")
    static let formatHeaders = String(localized: "Headers", comment: "Toolbar item to toggle heading levels")
    static let toggleBold = String(localized: "Bold", comment: "Toolbar item to toggle bold")
    static let toggleItalic = String(localized: "Italic", comment: "Toolbar item to toggle italic")
    static let toggleStrikethrough = String(localized: "Strikethrough", comment: "Toolbar item to toggle strikethrough")
    static let insertLink = String(localized: "Insert Link", comment: "Toolbar item to insert link")
    static let insertImage = String(localized: "Insert Image", comment: "Toolbar item to insert image")
    static let toggleList = String(localized: "Toggle List", comment: "Toolbar item to toggle bullet list")
    static let toggleBlockquote = String(localized: "Quote", comment: "Toolbar item to toggle blockquote")
    static let horizontalRule = String(localized: "Horizontal Rule", comment: "Toolbar item to insert horizontal rule")
    static let insertTable = String(localized: "Table", comment: "Toolbar item to insert table")
    static let insertCode = String(localized: "Insert Code", comment: "Toolbar item to insert code")
    static let textFormat = String(localized: "Text Format", comment: "Toolbar item to use text format menu")
    static let shareDocument = String(localized: "Share this document", comment: "Toolbar item to share the document")
    static let copyPandocCommand = String(localized: "Copy Pandoc Command", comment: "Toolbar item to copy pandoc command")
  }

  enum Search {
    static let find = String(localized: "Find", comment: "Find mode in search menu")
    static let replace = String(localized: "Replace", comment: "Replace mode in search menu")
    static let caseSensitive = String(localized: "Case Sensitive", comment: "Toggle case sensitive search")
    static let wholeWord = String(localized: "Whole Word", comment: "Toggle whole word search")
    static let literalSearch = String(localized: "Literal Search", comment: "Toggle literal search")
    static let regularExpression = String(localized: "Regular Expression", comment: "Toggle regular expression for search")
    static let recentSearches = String(localized: "Recent Searches", comment: "Menu item: recent searches")
    static let clearRecents = String(localized: "Clear Recents", comment: "Menu item: clear recents")
    static let findSelection = String(localized: "Find Selection", comment: "Menu item: use selection to find")
    static let selectAllOccurrences = String(localized: "Select All Occurrences", comment: "Menu item: select all occurrences")
  }

  enum Document {
    static let openDocument = String(localized: "Open Document", comment: "Menu item: open an existing document")
    static let newDocument = String(localized: "New Document", comment: "Menu item: create a new document")
    static let gotoLine = String(localized: "Go to Line", comment: "Placeholder text for goto line window")
  }

  enum Settings {
    // Editor
    static let editor = String(localized: "Editor", comment: "Window title for editor settings")
    static let font = String(localized: "Font:", comment: "Label for font settings")
    static let selectFont = String(localized: "Select...", comment: "Menu label for selecting fonts")
    static let systemDefault = String(localized: "System Default", comment: "System default font name")
    static let systemMono = String(localized: "System Mono", comment: "System mono font name")
    static let systemRounded = String(localized: "System Rounded", comment: "System rounded font name")
    static let systemSerif = String(localized: "System Serif", comment: "System serif font name")
    static let openFontPanel = String(localized: "Open Font Panel...", comment: "Menu item for selecting custom fonts")
    static let lightTheme = String(localized: "Light Theme:", comment: "Light theme for the editor")
    static let darkTheme = String(localized: "Dark Theme:", comment: "Dark theme for the editor")
    static let displayOptions = String(localized: "Show:", comment: "Label for display options")
    static let lineNumbers = String(localized: "Line numbers", comment: "Option to show line numbers")
    static let activeLineIndicator = String(localized: "Active line indicator", comment: "Option to show active line indicator")
    static let invisibleCharacters = String(localized: "Invisible characters", comment: "Option to show invisible characters")
    static let selectionStatus = String(localized: "Selection status", comment: "Option to show selection status")
    static let editBehavior = String(localized: "Edit Behavior:", comment: "Editor behavior like focus mode and typewriter mode")
    static let typewriterModeTitle = String(localized: "Keep caret in the middle", comment: "Explanation for typewriter mode")
    static let focusModeTitle = String(localized: "Dim inactive lines", comment: "Explanation for focus mode")
    static let lineWrappingLabel = String(localized: "Line Wrapping:", comment: "Label for line wrapping option")
    static let lineWrappingDescription = String(localized: "Wrap lines to editor width", comment: "Explanation for line wrapping option")
    static let lineHeight = String(localized: "Line Height:", comment: "Label for line height option")
    static let tightHeight = String(localized: "Tight", comment: "Tight line spacing")
    static let normalHeight = String(localized: "Normal", comment: "Normal line spacing")
    static let relaxedHeight = String(localized: "Relaxed", comment: "Relaxed line spacing")
    static let tabKeyBehavior = String(localized: "Tab Key:", comment: "Label for tab key behavior settings")
    static let insertsTab = String(localized: "Inserts tab character", comment: "Default tab key behavior")
    static let insertsTwoSpaces = String(localized: "Inserts 2 spaces", comment: "Press tab key to insert 2 spaces")
    static let insertsFourSpaces = String(localized: "Inserts 4 spaces", comment: "Press tab key to insert 4 spaces")
    static let indentUnit = String(localized: "Prefer Indent Using:", comment: "Label for indent unit settings")
    static let twoSpaces = String(localized: "2 spaces", comment: "Use 2 spaces as the indent unit")
    static let fourSpaces = String(localized: "4 spaces", comment: "Use 4 spaces as the indent unit")
    static let oneTab = String(localized: "1 tab", comment: "Use 1 tab as the indent unit")
    static let twoTabs = String(localized: "2 tabs", comment: "Use 2 tabs as the indent unit")

    // General
    static let general = String(localized: "General", comment: "Window title for general settings")
    static let appearance = String(localized: "Appearance:", comment: "Appearance for the app")
    static let system = String(localized: "System", comment: "Follow the system appearance")
    static let light = String(localized: "Light", comment: "Always use light mode for the app")
    static let dark = String(localized: "Dark", comment: "Always use dark mode for the app")
    static let newWindowBehavior = String(localized: "New Window Behavior:", comment: "Behavior when creating new windows")
    static let defaultTextEncoding = String(localized: "Default Text Encoding:", comment: "Text encoding for opening and saving files")
    static let defaultLineEndings = String(localized: "Default Line Endings:", comment: "Line endings for creating new files")
    static let macOSLineEndings = String(localized: "macOS / Unix (LF)", comment: "Line endings used on macOS and Unix")
    static let windowsLineEndings = String(localized: "Windows (CRLF)", comment: "Line endings used on Windows")
    static let classicMacLineEndings = String(localized: "Classic Mac OS (CR)", comment: "Line endings used on Classic Mac OS")

    // Window
    static let window = String(localized: "Window", comment: "Window title for window settings")
    static let toolbarMode = String(localized: "Toolbar Mode:", comment: "Label for window toolbar mode")
    static let normalMode = String(localized: "Normal", comment: "Normal mode for window toolbar")
    static let compactMode = String(localized: "Compact", comment: "Compact mode for window toolbar")
    static let hiddenMode = String(localized: "Hidden", comment: "Hidden mode for window toolbar")
    static let tabbingMode = String(localized: "Tabbing Mode:", comment: "Label for window tabbing mode settings")
    static let automatic = String(localized: "Automatic", comment: "Automatic window tabbing mode")
    static let preferred = String(localized: "Preferred", comment: "Preferred window tabbing mode")
    static let disallowed = String(localized: "Disallowed", comment: "Disallowed window tabbing mode")
    static let reduceTransparencyLabel = String(localized: "Reduce Transparency:", comment: "Label for the option to reduce window transparency")
    static let reduceTransparencyDescription = String(localized: "Remove the toolbar blur", comment: "Explanation for the option to reduce window transparency")
  }
}

// Icon set used in the app: https://developer.apple.com/sf-symbols/
//
// Note: double check availability and deployment target before adding new icons
enum Icons {
  static let arrowUturnBackwardCircle = "arrow.uturn.backward.circle"
  static let bold = "bold"
  static let characterCursorIbeam = "character.cursor.ibeam"
  static let chevronLeft = "chevron.left"
  static let chevronRight = "chevron.right"
  static let curlybracesSquare = "curlybraces.square"
  static let gearshape = "gearshape"
  static let italic = "italic"
  static let link = "link"
  static let listBullet = "list.bullet"
  static let listBulletRectangle = "list.bullet.rectangle"
  static let macwindow = "macwindow"
  static let number = "number"
  static let photo = "photo"
  static let squareAndArrowUp = "square.and.arrow.up"
  static let squareSplit1x2 = "square.split.1x2"
  static let strikethrough = "strikethrough"
  static let tablecells = "tablecells"
  static let terminal = "terminal"
  static let textQuote = "text.quote"
  static let textformat = "textformat"
}

extension EditorLocalizable {
  static var main: Self {
    EditorLocalizable(
      controlCharacter: Localized.Editor.controlCharacter,
      foldedLines: Localized.Editor.foldedLines,
      unfoldedLines: Localized.Editor.unfoldedLines,
      foldedCode: Localized.Editor.foldedCode,
      unfold: Localized.Editor.unfold,
      foldLine: Localized.Editor.foldLine,
      unfoldLine: Localized.Editor.unfoldLine,
      previewButtonTitle: Localized.Editor.previewButtonTitle
    )
  }
}
