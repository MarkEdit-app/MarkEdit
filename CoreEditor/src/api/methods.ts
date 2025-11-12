import { EditorView } from '@codemirror/view';
import { Extension } from '@codemirror/state';
import { LanguageDescription } from '@codemirror/language';
import { MarkdownConfig } from '@lezer/markdown';
import { CreateFileOptions, FileInfo, PasteboardItem } from 'markedit-api';
import { markdownConfigurations } from '../extensions';

export function onEditorReady(listener: (editorView: EditorView) => void) {
  storage.editorReadyListeners.push(listener);

  if (isEditorReady()) {
    listener(window.editor);
  }
}

export async function createFile(options: CreateFileOptions): Promise<boolean> {
  return window.nativeModules.api.createFile({ options });
}

export async function deleteFile(path: string): Promise<boolean> {
  return window.nativeModules.api.deleteFile({ path });
}

export async function listFiles(path: string): Promise<string[] | undefined> {
  return window.nativeModules.api.listFiles({ path });
}

export async function getFileContent(path?: string): Promise<string | undefined> {
  return window.nativeModules.api.getFileContent({ path });
}

export async function getFileInfo(path?: string): Promise<FileInfo | undefined> {
  const info = await window.nativeModules.api.getFileInfo({ path });

  // eslint-disable-next-line compat/compat
  return new Promise(resolve => {
    resolve(info === undefined ? undefined : (() => {
      const json: {
        filePath: string;
        fileSize: number;
        creationDate: number;
        modificationDate: number;
        parentPath: string;
        isDirectory: boolean;
      } = JSON.parse(info);

      return {
        filePath: json.filePath,
        fileSize: json.fileSize,
        creationDate: new Date(json.creationDate * 1000),
        modificationDate: new Date(json.modificationDate * 1000),
        parentPath: json.parentPath,
        isDirectory: json.isDirectory,
      };
    })());
  });
}

export async function getPasteboardItems(): Promise<PasteboardItem[]> {
  const items = await window.nativeModules.api.getPasteboardItems();
  return items === undefined ? [] : JSON.parse(items);
}

export function getPasteboardString(): Promise<string | undefined> {
  return window.nativeModules.api.getPasteboardString();
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

export { addMainMenuItem, showContextMenu, showAlert, showTextBox, showSavePanel, runService } from './ui';

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
