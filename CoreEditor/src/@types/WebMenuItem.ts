/**
 * Represents a menu item in native menus.
 */
export interface WebMenuItem {
  separator: boolean;
  title?: string;
  icon?: string;
  actionID?: string;
  stateGetterID?: string;
  key?: string;
  modifiers?: string[];
  children?: CodeGen_Self[];
}
