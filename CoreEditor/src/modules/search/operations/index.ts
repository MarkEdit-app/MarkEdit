export enum SearchOperation {
  selectAll = 'selectAll',
  selectAllInSelection = 'selectAllInSelection',
  replaceAll = 'replaceAll',
  replaceAllInSelection = 'replaceAllInSelection',
}

export { default as performReplaceAll } from './replaceAll';
export { default as performReplaceAllInSelection } from './replaceAllInSelection';
export { default as performSelectAll } from './selectAll';
export { default as performSelectAllInSelection } from './selectAllInSelection';
