/**
 * Represents a menu item in native menus.
 */
export interface WebMenuItem {
  id: string;
  separator: boolean;
  title?: string;
  key?: string;
  modifiers?: string[];
  children?: CodeGen_Self[];
}
