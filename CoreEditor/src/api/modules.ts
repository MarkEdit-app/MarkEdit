import * as cmView from '@codemirror/view';
import * as cmState from '@codemirror/state';
import * as cmLanguage from '@codemirror/language';
import * as cmCommands from '@codemirror/commands';
import * as cmSearch from '@codemirror/search';

import * as lezerCommon from '@lezer/common';
import * as lezerHighlight from '@lezer/highlight';
import * as lezerMarkdown from '@lezer/markdown';
import * as lezerLr from '@lezer/lr';

import * as customHistory from '../@vendor/commands/history';

import { TextEditor } from './editor';
import {
  onEditorReady,
  getFileInfo,
  getPasteboardItems,
  getPasteboardString,
  addExtension,
  addMarkdownConfig,
  addCodeLanguage,
  addMainMenuItem,
  showContextMenu,
  showAlert,
  showTextBox,
  showSavePanel,
} from './methods';

export function initMarkEditModules() {
  const codemirror = {
    view: cmView,
    state: cmState,
    language: cmLanguage,
    commands: {
      ...cmCommands,
      ...customHistory,
    },
    search: cmSearch,
  };

  const lezer = {
    common: lezerCommon,
    highlight: lezerHighlight,
    markdown: lezerMarkdown,
    lr: lezerLr,
  };

  MarkEdit.editorAPI = new TextEditor();
  MarkEdit.codemirror = codemirror;
  MarkEdit.lezer = lezer;

  MarkEdit.onEditorReady = onEditorReady;
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
    '@codemirror/commands': codemirror.commands,
    '@codemirror/search': codemirror.search,
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
