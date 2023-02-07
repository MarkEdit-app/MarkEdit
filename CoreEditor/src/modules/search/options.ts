export default interface SearchOptions {
  search: string;
  caseSensitive: boolean;
  literal: boolean;
  regexp: boolean;
  wholeWord: boolean;
  replace?: string;
}
