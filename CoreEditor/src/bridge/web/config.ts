import { WebModule } from '../webModule';
import { WebFontFace, InvisiblesBehavior } from '../../config';
import { TabKeyBehavior } from '../../modules/indentation';

import {
  setTheme,
  setFontFace,
  setFontSize,
  setShowLineNumbers,
  setShowActiveLineIndicator,
  setInvisiblesBehavior,
  setReadOnlyMode,
  setTypewriterMode,
  setFocusMode,
  setLineWrapping,
  setLineHeight,
  setIndentParagraphs,
  setDefaultLineBreak,
  setTabKeyBehavior,
  setIndentUnit,
  setSuggestWhileTyping,
  setAutoCharacterPairs,
} from '../../modules/config';

/**
 * @shouldExport true
 * @invokePath config
 * @overrideModuleName WebBridgeConfig
 */
export interface WebModuleConfig extends WebModule {
  setTheme({ name }: { name: string }): void;
  setFontFace({ fontFace }: { fontFace: WebFontFace }): void;
  setFontSize({ fontSize }: { fontSize: number }): void;
  setShowLineNumbers({ enabled }: { enabled: boolean }): void;
  setShowActiveLineIndicator({ enabled }: { enabled: boolean }): void;
  setInvisiblesBehavior({ behavior }: { behavior: InvisiblesBehavior }): void;
  setReadOnlyMode({ enabled }: { enabled: boolean }): void;
  setTypewriterMode({ enabled }: { enabled: boolean }): void;
  setFocusMode({ enabled }: { enabled: boolean }): void;
  setLineWrapping({ enabled }: { enabled: boolean }): void;
  setLineHeight({ lineHeight }: { lineHeight: number }): void;
  setIndentParagraphs({ enabled }: { enabled: boolean }): void;
  setDefaultLineBreak({ lineBreak }: { lineBreak?: string }): void;
  setTabKeyBehavior({ behavior }: { behavior: TabKeyBehavior }): void;
  setIndentUnit({ unit }: { unit: string }): void;
  setSuggestWhileTyping({ enabled }: { enabled: boolean }): void;
  setAutoCharacterPairs({ enabled }: { enabled: boolean }): void;
}

export class WebModuleConfigImpl implements WebModuleConfig {
  setTheme({ name }: { name: string }): void {
    setTheme(name);
  }

  setFontFace({ fontFace }: { fontFace: WebFontFace }): void {
    setFontFace(fontFace);
  }

  setFontSize({ fontSize }: { fontSize: number }): void {
    setFontSize(fontSize);
  }

  setShowLineNumbers({ enabled }: { enabled: boolean }): void {
    setShowLineNumbers(enabled);
  }

  setShowActiveLineIndicator({ enabled }: { enabled: boolean }): void {
    setShowActiveLineIndicator(enabled);
  }

  setInvisiblesBehavior({ behavior }: { behavior: InvisiblesBehavior }): void {
    setInvisiblesBehavior(behavior, true);
  }

  setReadOnlyMode({ enabled }: { enabled: boolean }): void {
    setReadOnlyMode(enabled);
  }

  setTypewriterMode({ enabled }: { enabled: boolean }): void {
    setTypewriterMode(enabled);
  }

  setFocusMode({ enabled }: { enabled: boolean }): void {
    setFocusMode(enabled);
  }

  setLineWrapping({ enabled }: { enabled: boolean }): void {
    setLineWrapping(enabled);
  }

  setLineHeight({ lineHeight }: { lineHeight: number }): void {
    setLineHeight(lineHeight);
  }

  setIndentParagraphs({ enabled }: { enabled: boolean }): void {
    setIndentParagraphs(enabled);
  }

  setDefaultLineBreak({ lineBreak }: { lineBreak?: string }): void {
    setDefaultLineBreak(lineBreak);
  }

  setTabKeyBehavior({ behavior }: { behavior: TabKeyBehavior }): void {
    setTabKeyBehavior(behavior);
  }

  setIndentUnit({ unit }: { unit: string }): void {
    setIndentUnit(unit);
  }

  setSuggestWhileTyping({ enabled }: { enabled: boolean }): void {
    setSuggestWhileTyping(enabled);
  }

  setAutoCharacterPairs({ enabled }: { enabled: boolean }): void {
    setAutoCharacterPairs(enabled);
  }
}
