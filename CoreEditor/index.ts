import { Config, IndentBehavior, InvisiblesBehavior } from './src/config';
import { isReleaseMode } from './src/common/utils';

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
import { WebModuleAPIImpl } from './src/bridge/web/api';
import { WebModuleWritingToolsImpl } from './src/bridge/web/writingTools';
import { WebModuleFoundationModelsImpl } from './src/bridge/web/foundationModels';

import { pseudoDocument } from './test/utils/mock';
import { createNativeModule } from './src/bridge/nativeModule';
import { NativeModuleCore } from './src/bridge/native/core';
import { NativeModuleCompletion } from './src/bridge/native/completion';
import { NativeModulePreview } from './src/bridge/native/preview';
import { NativeModuleTokenizer } from './src/bridge/native/tokenizer';
import { NativeModuleAPI } from './src/bridge/native/api';
import { NativeModuleFoundationModels } from './src/bridge/native/foundationModels';
import { NativeModuleTranslation } from './src/bridge/native/translation';

import { resetEditor } from './src/core';
import { initThemeExtractors, initMarkEditModules } from './src/api/modules';
import { setUp } from './src/styling/config';
import { loadTheme } from './src/styling/themes';
import { startObserving } from './src/modules/events';

// Initialize and inject modules to the global MarkEdit object
initMarkEditModules();
initThemeExtractors();

// In release mode, window.config = "{{EDITOR_CONFIG}}" will be replaced with a JSON literal
const config = import.meta.env.PROD ? window.config : {
  text: pseudoDocument,
  theme: 'github-light',
  fontFace: { family: 'SF Mono, ui-monospace' },
  fontSize: 17,
  showLineNumbers: true,
  showActiveLineIndicator: true,
  invisiblesBehavior: InvisiblesBehavior.always,
  readOnlyMode: false,
  typewriterMode: false,
  focusMode: false,
  lineWrapping: true,
  lineHeight: 1.5,
  suggestWhileTyping: false,
  autoCharacterPairs: true,
  indentBehavior: IndentBehavior.paragraph,
  standardDirectories: {},
  localizable: {
    previewButtonTitle: 'Preview',
    cmdClickToFollow: '⌘-click to follow',
    cmdClickToToggleTodo: '⌘-click to toggle todo',
  },
} as Config;

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
  api: new WebModuleAPIImpl(),
  writingTools: new WebModuleWritingToolsImpl(),
  foundationModels: new WebModuleFoundationModelsImpl(),
};

window.nativeModules = {
  core: createNativeModule<NativeModuleCore>('core'),
  completion: createNativeModule<NativeModuleCompletion>('completion'),
  preview: createNativeModule<NativeModulePreview>('preview'),
  tokenizer: createNativeModule<NativeModuleTokenizer>('tokenizer'),
  api: createNativeModule<NativeModuleAPI>('api'),
  foundationModels: createNativeModule<NativeModuleFoundationModels>('foundationModels'),
  translation: createNativeModule<NativeModuleTranslation>('translation'),
};

window.onload = () => {
  window.nativeModules.core.notifyWindowDidLoad();

  // On Prod, text is reset by the native code
  if (!isReleaseMode) {
    window.config = config;
    resetEditor(config.text);
  }
};

setUp(config, loadTheme(config.theme).colors);
startObserving();
