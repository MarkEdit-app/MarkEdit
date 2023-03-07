import { EditorView } from '@codemirror/view';
import { Config, Dynamics } from '../config';
import { WebModule } from '../bridge/webModule';
import { NativeReply } from '../bridge/nativeModule';
import { NativeModuleCore } from '../bridge/native/core';
import { NativeModuleCompletion } from '../bridge/native/completion';
import { NativeModulePreview } from '../bridge/native/preview';
import { NativeModuleTokenizer } from '../bridge/native/tokenizer';

declare global {
  type CodeGen_Int = number & { _brand: never };
}

interface WebKit {
  messageHandlers?: {
    bridge?: {
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      postMessage: (object: any) => void;
    };
  };
}

declare global {
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
    };
    handleNativeReply: (reply: NativeReply) => void;
  }

  interface ImportMetaEnv {
    readonly PROD: boolean;
  }

  interface ImportMeta {
    readonly env: ImportMetaEnv;
  }
}

export {};
