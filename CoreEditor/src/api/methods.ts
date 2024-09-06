import { EditorView } from '@codemirror/view';
import { Extension } from '@codemirror/state';
import { MarkdownConfig } from '@lezer/markdown';
import { markdownExtensionBundle } from '../extensions';

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

  if (isEditorReady()) {
    window.editor.dispatch({
      effects: window.dynamics.markdownConfigurator?.reconfigure(markdownExtensionBundle()),
    });
  }
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

function isEditorReady() {
  return typeof window.editor.dispatch === 'function';
}

const storage: {
  editorReadyListeners: ((editorView: EditorView) => void)[];
  extensions: Extension[];
  markdownConfigs: MarkdownConfig[];
} = {
  editorReadyListeners: [],
  extensions: [],
  markdownConfigs: [],
};
