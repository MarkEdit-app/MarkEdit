import { EditorView } from '@codemirror/view';
import { Extension } from '@codemirror/state';
import { LanguageDescription, LanguageSupport } from '@codemirror/language';
import { MarkdownConfig } from '@lezer/markdown';
import { RuntimeInfo } from 'markedit-api';
import { markdownConfigurations } from '../extensions';

type EditorReadyListener = (editor: EditorView) => void;
type HTMLConfig = { matchClosingTags?: boolean };
type HTMLLanguage = (config?: HTMLConfig) => LanguageSupport;

export function onAppReady(listener: () => void) {
  storage.appReadyListeners.push(listener);
}

export function onEditorReady(listener: EditorReadyListener) {
  storage.editorReadyListeners.push(listener);

  if (isEditorReady()) {
    notifyEditorReadySafely(listener, window.editor);
  }
}

export function notifyAppReady() {
  storage.appReadyListeners.forEach(listener => listener());
  storage.appReadyListeners = [];
}

export async function saveDocument(): Promise<boolean> {
  return window.nativeModules.api.saveDocument();
}

export async function closeDocument(): Promise<boolean> {
  return window.nativeModules.api.closeDocument();
}

export function runtimeInfo(): RuntimeInfo {
  const runtimeInfo = window.config.runtimeInfo;
  if (runtimeInfo === undefined) {
    throw new Error('MarkEdit.runtimeInfo() is not implemented in this context.');
  }

  return runtimeInfo;
}

export function terminateApp(): void {
  window.nativeModules.api.terminateApp();
}

export function relaunchApp(): void {
  window.nativeModules.api.relaunchApp();
}

export function addExtension(extension: Extension) {
  storage.extensions.push(extension);

  if (isEditorReady()) {
    window.editor.dispatch({
      effects: window.dynamics.extensionConfigurator?.reconfigure(userExtensions()),
    });
  }
}

export function addMarkdownConfig(config: MarkdownConfig | MarkdownConfig[]) {
  if (Array.isArray(config)) {
    storage.markdownConfigs.push(...config);
  } else {
    storage.markdownConfigs.push(config);
  }

  reconfigureMarkdown();
}

export function addCodeLanguage(language: LanguageDescription | LanguageDescription[]) {
  if (Array.isArray(language)) {
    storage.codeLanguages.push(...language);
  } else {
    storage.codeLanguages.push(language);
  }

  reconfigureMarkdown();
}

export function overrideHTMLLanguage(html: HTMLLanguage) {
  storage.htmlLanguage = html;
  reconfigureMarkdown();
}

export function notifyEditorReady(editorView: EditorView) {
  const listeners = storage.editorReadyListeners;
  listeners.forEach(listener => notifyEditorReadySafely(listener, editorView));
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

export function userHTMLLanguage(): HTMLLanguage | undefined {
  return storage.htmlLanguage;
}

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

function notifyEditorReadySafely(listener: EditorReadyListener, editorView: EditorView) {
  try {
    listener(editorView);
  } catch (error) {
    console.error('Failed to notify an editor-ready listener:', error);
  }
}

const storage: {
  appReadyListeners: (() => void)[];
  editorReadyListeners: EditorReadyListener[];
  extensions: Extension[];
  markdownConfigs: MarkdownConfig[];
  codeLanguages: LanguageDescription[];
  htmlLanguage?: HTMLLanguage;
} = {
  appReadyListeners: [],
  editorReadyListeners: [],
  extensions: [],
  markdownConfigs: [],
  codeLanguages: [],
  htmlLanguage: undefined,
};
