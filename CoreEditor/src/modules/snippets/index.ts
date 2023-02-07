import insertSnippet from './insertSnippet';

export function insertHyperLink(title: string, url: string, prefix = '') {
  insertSnippet(`${prefix}[#{${title}}](#{${url}})`);
}

export function insertTable(columnName: string, itemName: string) {
  // It's merely a trivial approach,
  // we don't want to spend time improving it,
  // using tables in Markdown can hardly be great.
  //
  // Let's just use this as a hint for those who are not familiar with the syntax.
  insertSnippet([
    `| #{${columnName} 1} | #{${columnName} 2} | #{${columnName} 3} |`,
    '|:----|:---:|:---:|',
    `| #{${itemName} 1} | #{${itemName} 2} | #{${itemName} 3} |`,
    `| #{${itemName} 4} | #{${itemName} 5} | #{${itemName} 6} |`,
  ].join(window.editor.state.lineBreak));
}
