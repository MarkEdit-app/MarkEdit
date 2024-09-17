import { EditorView } from '@codemirror/view';
import { Extension } from '@codemirror/state';
import { LanguageDescription } from '@codemirror/language';
import { MarkdownConfig } from '@lezer/markdown';
import { markdownConfigurations } from '../extensions';

export function onEditorReady(listener: (editorView: EditorView) => void) {
  storage.editorReadyListeners.push(listener);

  if (isEditorReady()) {
    listener(window.editor);
  }
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
