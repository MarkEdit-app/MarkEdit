import { WebModule } from '../webModule';
import {
  EditCommand,
  toggleBold,
  toggleItalic,
  toggleStrikethrough,
  toggleHeading,
  toggleBullet,
  toggleNumbering,
  toggleTodo,
  toggleBlockquote,
  toggleInlineCode,
  toggleInlineMath,
  insertCodeBlock,
  insertMathBlock,
  insertHorizontalRule,
  performEditCommand,
} from '../../modules/commands';

import { insertHyperLink, insertTable } from '../../modules/snippets';

/**
 * @shouldExport true
 * @invokePath format
 * @overrideModuleName WebBridgeFormat
 */
export interface WebModuleFormat extends WebModule {
  toggleBold(): void;
  toggleItalic(): void;
  toggleStrikethrough(): void;
  toggleHeading({ level }: { level: CodeGen_Int }): void;
  toggleBullet(): void;
  toggleNumbering(): void;
  toggleTodo(): void;
  toggleBlockquote(): void;
  toggleInlineCode(): void;
  toggleInlineMath(): void;
  insertCodeBlock(): void;
  insertMathBlock(): void;
  insertHorizontalRule(): void;
  insertHyperLink({ title, url, prefix }: { title: string; url: string; prefix?: string }): void;
  insertTable({ columnName, itemName }: { columnName: string; itemName: string }): void;
  performEditCommand({ command }: { command: EditCommand }): void;
}

export class WebModuleFormatImpl implements WebModuleFormat {
  toggleBold(): void {
    toggleBold();
  }

  toggleItalic(): void {
    toggleItalic();
  }

  toggleStrikethrough(): void {
    toggleStrikethrough();
  }

  toggleHeading({ level }: { level: CodeGen_Int }): void {
    toggleHeading(level);
  }

  toggleBullet(): void {
    toggleBullet();
  }

  toggleNumbering(): void {
    toggleNumbering();
  }

  toggleTodo(): void {
    toggleTodo();
  }

  toggleBlockquote(): void {
    toggleBlockquote();
  }

  toggleInlineCode(): void {
    toggleInlineCode();
  }

  toggleInlineMath(): void {
    toggleInlineMath();
  }

  insertCodeBlock(): void {
    insertCodeBlock();
  }

  insertMathBlock(): void {
    insertMathBlock();
  }

  insertHorizontalRule(): void {
    insertHorizontalRule();
  }

  insertHyperLink({ title, url, prefix }: { title: string; url: string; prefix?: string }): void {
    insertHyperLink(title, url, prefix);
  }

  insertTable({ columnName, itemName }: { columnName: string; itemName: string }): void {
    insertTable(columnName, itemName);
  }

  performEditCommand({ command }: { command: EditCommand }): void {
    performEditCommand(command);
  }
}
