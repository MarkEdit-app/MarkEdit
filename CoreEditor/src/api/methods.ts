import { EditorView } from '@codemirror/view';
import { Extension } from '@codemirror/state';
import { LanguageDescription } from '@codemirror/language';
import { MarkdownConfig } from '@lezer/markdown';
import { FileInfo } from 'markedit-api';
import { markdownConfigurations } from '../extensions';

export function onEditorReady(listener: (editorView: EditorView) => void) {
  storage.editorReadyListeners.push(listener);

  if (isEditorReady()) {
    listener(window.editor);
  }
}

export async function getFileInfo(): Promise<FileInfo | undefined> {
  const info = await window.nativeModules.core.getFileInfo();

  // eslint-disable-next-line compat/compat
  return new Promise(resolve => {
    resolve(info === undefined ? undefined : (() => {
      const json: {
        filePath: string;
        fileSize: number;
        creationDate: number;
        modificationDate: number;
      } = JSON.parse(info);

      return {
        filePath: json.filePath,
        fileSize: json.fileSize,
        creationDate: new Date(json.creationDate * 1000),
        modificationDate: new Date(json.modificationDate * 1000),
      };
    })());
  });
}

export function addExtension(extension: Extension) {
  storage.extensions.push(extension);

  if (isEditorReady()) {
    window.editor.dispatch({
      effects: window.dynamics.extensionConfigurator?.reconfigure(userExtensions()),
    });
  }
}

export function addMarkdownConfig(config: MarkdownConfig) {
  storage.markdownConfigs.push(config);
  reconfigureMarkdown();
}

export function addCodeLanguage(language: LanguageDescription) {
  storage.codeLanguages.push(language);
  reconfigureMarkdown();
}

export function editorReadyListeners() {
  return storage.editorReadyListeners;
}

export function userExtensions(): Extension[] {
  return storage.extensions;
}

export function userMarkdownConfigs(): MarkdownConfig[] {
  return storage.markdownConfigs;
}

export function userCodeLanguages(): LanguageDescription[] {
  return storage.codeLanguages;
}

export { addMainMenuItem, showContextMenu, showAlert, showTextBox } from './ui';

function reconfigureMarkdown() {
  if (isEditorReady()) {
    window.editor.dispatch({
      effects: window.dynamics.markdownConfigurator?.reconfigure(markdownConfigurations()),
    });
  }
}

function isEditorReady() {
  return typeof window.editor.dispatch === 'function';
}

const storage: {
  editorReadyListeners: ((editorView: EditorView) => void)[];
  extensions: Extension[];
  markdownConfigs: MarkdownConfig[];
  codeLanguages: LanguageDescription[];
} = {
  editorReadyListeners: [],
  extensions: [],
  markdownConfigs: [],
  codeLanguages: [],
};
