export default interface SearchOptions {
  search: string;
  caseSensitive: boolean;
  diacriticInsensitive: boolean;
  wholeWord: boolean;
  literal: boolean;
  regexp: boolean;
  refocus: boolean;
  replace?: string;
}
