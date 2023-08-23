export default interface SearchOptions {
  search: string;
  caseSensitive: boolean;
  literal: boolean;
  regexp: boolean;
  wholeWord: boolean;
  refocus: boolean;
  replace?: string;
}
