import { Config, InvisiblesBehavior } from './src/config';
import { isProd } from './src/common/env';

import { WebModuleConfigImpl } from './src/bridge/web/config';
import { WebModuleCoreImpl } from './src/bridge/web/core';
import { WebModuleCompletionImpl } from './src/bridge/web/completion';
import { WebModuleHistoryImpl } from './src/bridge/web/history';
import { WebModuleLineEndingsImpl } from './src/bridge/web/lineEndings';
import { WebModuleTextCheckerImpl } from './src/bridge/web/textChecker';
import { WebModuleSelectionImpl } from './src/bridge/web/selection';
import { WebModuleFormatImpl } from './src/bridge/web/format';
import { WebModuleSearchImpl } from './src/bridge/web/search';
import { WebModuleTableOfContentsImpl } from './src/bridge/web/toc';
import { WebModuleGrammarlyImpl } from './src/bridge/web/grammarly';

import { pseudoDocument } from './src/@test/mock';
import { createNativeModule } from './src/bridge/nativeModule';
import { NativeModuleCore } from './src/bridge/native/core';
import { NativeModuleCompletion } from './src/bridge/native/completion';
import { NativeModulePreview } from './src/bridge/native/preview';
import { NativeModuleTokenizer } from './src/bridge/native/tokenizer';

import * as core from './src/core';
import * as styling from './src/styling/config';
import * as themes from './src/styling/themes';
import * as events from './src/events';
import * as grammarly from './src/modules/grammarly';

// "{{EDITOR_CONFIG}}" will be replaced with a JSON literal in production
// eslint-disable-next-line @typescript-eslint/no-explicit-any
const config: Config = isProd ? ('{{EDITOR_CONFIG}}' as any) : {
  text: pseudoDocument,
  theme: 'github-light',
  fontFamily: 'monospace',
  fontSize: 17,
  showLineNumbers: true,
  showActiveLineIndicator: true,
  invisiblesBehavior: InvisiblesBehavior.always,
  typewriterMode: false,
  focusMode: false,
  lineWrapping: true,
  lineHeight: 1.5,
  suggestWhileTyping: false,
  localizable: {
    previewButtonTitle: 'preview',
    cmdClickToOpenLink: '⌘-click to open link',
  },
};

window.webModules = {
  config: new WebModuleConfigImpl(),
  core: new WebModuleCoreImpl(),
  completion: new WebModuleCompletionImpl(),
  history: new WebModuleHistoryImpl(),
  lineEndings: new WebModuleLineEndingsImpl(),
  textChecker: new WebModuleTextCheckerImpl(),
  selection: new WebModuleSelectionImpl(),
  format: new WebModuleFormatImpl(),
  search: new WebModuleSearchImpl(),
  toc: new WebModuleTableOfContentsImpl(),
  grammarly: new WebModuleGrammarlyImpl(),
};

window.nativeModules = {
  core: createNativeModule<NativeModuleCore>('core'),
  completion: createNativeModule<NativeModuleCompletion>('completion'),
  preview: createNativeModule<NativeModulePreview>('preview'),
  tokenizer: createNativeModule<NativeModuleTokenizer>('tokenizer'),
};

window.onload = () => {
  window.config = config;
  window.nativeModules.core.notifyWindowDidLoad();

  // On Prod, text is reset by the native code
  if (!isProd) {
    core.resetEditor(config.text);
  }
};

styling.setUp(config, themes.loadTheme(config.theme).accentColor);
events.startObserving();
grammarly.trottleMutations();
