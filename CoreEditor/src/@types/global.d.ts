import { EditorView } from '@codemirror/view';
import { Config, Dynamics } from '../config';
import { WebModule } from '../bridge/webModule';
import { NativeModuleCore } from '../bridge/native/core';
import { NativeModuleCompletion } from '../bridge/native/completion';
import { NativeModulePreview } from '../bridge/native/preview';
import { NativeModuleTokenizer } from '../bridge/native/tokenizer';
import { NativeModuleUI } from '../bridge/native/ui';

import type { MarkEdit } from 'markedit-api';

declare global {
  type CodeGen_Int = number & { _brand: never };
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  type CodeGen_Self = any & { _brand: never };
  // eslint-disable-next-line @typescript-eslint/no-explicit-any
  type CodeGen_Dict = any & { _brand: never };
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
  const MarkEdit: MarkEdit;

  interface Window {
    webkit?: WebKit;
    editor: EditorView;
    config: Config;
    dynamics: Dynamics;
    webModules: Record<string, WebModule>;
    nativeModules: {
      core: NativeModuleCore;
      completion: NativeModuleCompletion;
      preview: NativeModulePreview;
      tokenizer: NativeModuleTokenizer;
      ui: NativeModuleUI;
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
