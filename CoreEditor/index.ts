import { Config, InvisiblesBehavior } from './src/config';
import { isProd } from './src/common/utils';

import { WebModuleConfigImpl } from './src/bridge/web/config';
import { WebModuleCoreImpl } from './src/bridge/web/core';
import { WebModuleHistoryImpl } from './src/bridge/web/history';
import { WebModuleLineEndingsImpl } from './src/bridge/web/lineEndings';
import { WebModuleTextCheckerImpl } from './src/bridge/web/textChecker';
import { WebModuleSelectionImpl } from './src/bridge/web/selection';
import { WebModuleFormatImpl } from './src/bridge/web/format';
import { WebModuleSearchImpl } from './src/bridge/web/search';
import { WebModuleTableOfContentsImpl } from './src/bridge/web/toc';
import { WebModuleGrammarlyImpl } from './src/bridge/web/grammarly';

import { pseudoDocument } from './src/@test/mock';
import { createNativeModule, handleNativeReply } from './src/bridge/nativeModule';
import { NativeModuleCore } from './src/bridge/native/core';
import { NativeModulePreview } from './src/bridge/native/preview';

import * as core from './src/core';
import * as styling from './src/styling/config';
import * as themes from './src/styling/themes';
import * as events from './src/dom/events';

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
  localizable: {
    previewButtonTitle: 'preview',
  },
};

window.webModules = {
  config: new WebModuleConfigImpl(),
  core: new WebModuleCoreImpl(),
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
  preview: createNativeModule<NativeModulePreview>('preview'),
};

window.onload = () => {
  window.config = config;
  window.handleNativeReply = handleNativeReply;
  window.nativeModules.core.notifyWindowDidLoad();

  // On Prod, text is reset by the native code
  if (!isProd) {
    core.resetEditor(config.text);
  }
};

styling.setUp(config, themes.loadTheme(config.theme).accentColor);
events.startObserving();
