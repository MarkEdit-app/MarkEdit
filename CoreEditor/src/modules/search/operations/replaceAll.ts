import { replaceAll as replaceAllCommand } from '@codemirror/search';

export default function replaceAll() {
  replaceAllCommand(window.editor);
}
