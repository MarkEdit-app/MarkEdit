import { EditorView } from '@codemirror/view';
import { Config, Dynamics } from '../config';
import { EditorColors } from '../styling/types';
import { WebModule } from '../bridge/webModule';
import { NativeModuleCore } from '../bridge/native/core';
import { NativeModuleCompletion } from '../bridge/native/completion';
import { NativeModulePreview } from '../bridge/native/preview';
import { NativeModuleTokenizer } from '../bridge/native/tokenizer';
import { TextEditor } from '../api/editor';

import type { Extension } from '@codemirror/state';
import type { MarkdownConfig } from '@lezer/markdown';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  type CodeGen_Dict = any & { _brand: never };
  type CodeGen_Int = number & { _brand: never };
}

interface WebKit {
  messageHandlers?: {
    bridge?: {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      postMessage: (object: any) => Promise<any>;
    };
  };
}

declare global {
  // https://github.com/MarkEdit-app/MarkEdit-api
  const MarkEdit: {
    editorView: EditorView;
    editorAPI: TextEditor;
    codemirror: { view: Module; state: Module; language: Module; commands: Module; search: Module };
    lezer: { common: Module; highlight: Module; markdown: Module; lr: Module };
    onEditorReady: (listener: (editorView: EditorView) => void) => void;
    addExtension: (extension: Extension) => void;
    addMarkdownConfig: (config: MarkdownConfig) => void;
  };

  interface Window {
    webkit?: WebKit;
    editor: EditorView;
    config: Config;
    colors?: EditorColors;
    dynamics: Dynamics;
    webModules: Record<string, WebModule>;
    nativeModules: {
      core: NativeModuleCore;
      completion: NativeModuleCompletion;
      preview: NativeModulePreview;
      tokenizer: NativeModuleTokenizer;
    };
  }

  interface ImportMetaEnv {
    readonly PROD: boolean;
  }

  interface ImportMeta {
    readonly env: ImportMetaEnv;
  }
}

export {};
