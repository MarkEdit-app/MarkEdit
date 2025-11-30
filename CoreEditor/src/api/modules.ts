import * as cmView from '@codemirror/view';
import * as cmState from '@codemirror/state';
import * as cmLanguage from '@codemirror/language';
import * as cmLangMarkdown from '../@vendor/lang-markdown';
import * as cmCommands from '@codemirror/commands';
import * as cmSearch from '@codemirror/search';
import * as cmAutocomplete from '@codemirror/autocomplete';

import * as lezerCommon from '@lezer/common';
import * as lezerHighlight from '@lezer/highlight';
import * as lezerMarkdown from '@lezer/markdown';
import * as lezerLr from '@lezer/lr';

import * as customHistory from '../@vendor/commands/history';

import { TextEditor } from './editor';
import { Translator } from './translation';
import { languageModel } from './languageModel';

import { onEditorReady, addExtension, addMarkdownConfig, addCodeLanguage } from './methods';
import { addMainMenuItem, showContextMenu, showAlert, showTextBox, showSavePanel, runService } from './ui';
import { createFile, deleteFile, listFiles, getFileContent, getFileInfo } from './files';
import { getPasteboardItems, getPasteboardString } from './pasteboard';

export function initMarkEditModules() {
  const codemirror = {
    view: cmView,
    state: cmState,
    language: cmLanguage,
    langMarkdown: cmLangMarkdown,
    commands: {
      ...cmCommands,
      ...customHistory,
    },
    search: cmSearch,
    autocomplete: cmAutocomplete,
  };

  const lezer = {
    common: lezerCommon,
    highlight: lezerHighlight,
    markdown: lezerMarkdown,
    lr: lezerLr,
  };

  MarkEdit.editorAPI = new TextEditor();
  MarkEdit.translationService = new Translator();
  MarkEdit.languageModel = languageModel;
  MarkEdit.codemirror = codemirror;
  MarkEdit.lezer = lezer;

  MarkEdit.onEditorReady = onEditorReady;
  MarkEdit.createFile = createFile;
  MarkEdit.deleteFile = deleteFile;
  MarkEdit.listFiles = listFiles;
  MarkEdit.getFileContent = getFileContent;
  MarkEdit.getFileInfo = getFileInfo;
  MarkEdit.getPasteboardItems = getPasteboardItems;
  MarkEdit.getPasteboardString = getPasteboardString;
  MarkEdit.addExtension = addExtension;
  MarkEdit.addMarkdownConfig = addMarkdownConfig;
  MarkEdit.addCodeLanguage = addCodeLanguage;
  MarkEdit.addMainMenuItem = addMainMenuItem;
  MarkEdit.showContextMenu = showContextMenu;
  MarkEdit.showAlert = showAlert;
  MarkEdit.showTextBox = showTextBox;
  MarkEdit.showSavePanel = showSavePanel;
  MarkEdit.runService = runService;

  // Override the share method to provide a clear error message
  navigator.share = (_: ShareData): Promise<void> => {
    // eslint-disable-next-line compat/compat
    return Promise.reject(new Error(
      'Navigator.share() is not allowed in this context. Use MarkEdit.showSavePanel() instead.',
    ));
  };

  const modules = {
    'markedit-api': { MarkEdit },
    '@codemirror/view': codemirror.view,
    '@codemirror/state': codemirror.state,
    '@codemirror/language': codemirror.language,
    '@codemirror/lang-markdown': codemirror.langMarkdown,
    '@codemirror/commands': codemirror.commands,
    '@codemirror/search': codemirror.search,
    '@codemirror/autocomplete': codemirror.autocomplete,
    '@lezer/common': lezer.common,
    '@lezer/highlight': lezer.highlight,
    '@lezer/markdown': lezer.markdown,
    '@lezer/lr': lezer.lr,
  };

  const require = (id: string) => {
    // eslint-disable-next-line @typescript-eslint/no-explicit-any
    const module = (modules as any)[id];
    if (module !== undefined) {
      return module;
    }

    console.error(`Failed to require module: "${id}", supported modules: ${Object.keys(modules).join(', ')}`);
    return {};
  };

  window.require = require as NodeJS.Require;
}

export function initThemeExtractors() {
  type Theme = cmState.Extension & {
    value?: {
      rules?: string[];
      specs?: cmLanguage.TagStyle[];
    };
  };

  // Private methods used in MarkEdit-theming to stably extract theme properties
  window.__extractStyleRules__ = (theme: Theme) => theme.value?.rules;
  window.__extractHighlightSpecs__ = (theme: Theme) => theme.value?.specs;
}
