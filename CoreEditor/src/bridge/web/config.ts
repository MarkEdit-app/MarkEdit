import { WebModule } from '../webModule';
import { TabKeyBehavior } from '../../modules/indentation';

import {
  setTheme,
  setFontFamily,
  setFontSize,
  setShowLineNumbers,
  setShowActiveLineIndicator,
  setShowInvisibles,
  setTypewriterMode,
  setFocusMode,
  setLineWrapping,
  setLineHeight,
  setDefaultLineBreak,
  setTabKeyBehavior,
  setIndentUnit,
} from '../../modules/config';

/**
 * @shouldExport true
 * @invokePath config
 * @overrideModuleName WebBridgeConfig
 */
export interface WebModuleConfig extends WebModule {
  setTheme({ name }: { name: string }): void;
  setFontFamily({ fontFamily }: { fontFamily: string }): void;
  setFontSize({ fontSize }: { fontSize: number }): void;
  setShowLineNumbers({ enabled }: { enabled: boolean } ): void;
  setShowActiveLineIndicator({ enabled }: { enabled: boolean }): void;
  setShowInvisibles({ enabled }: { enabled: boolean }): void;
  setTypewriterMode({ enabled }: { enabled: boolean }): void;
  setFocusMode({ enabled }: { enabled: boolean }): void;
  setLineWrapping({ enabled }: { enabled: boolean }): void;
  setLineHeight({ lineHeight }: { lineHeight: number }): void;
  setDefaultLineBreak({ lineBreak }: { lineBreak?: string }): void;
  setTabKeyBehavior({ behavior }: { behavior: TabKeyBehavior }): void;
  setIndentUnit({ unit }: { unit: string }): void;
}

export class WebModuleConfigImpl implements WebModuleConfig {
  setTheme({ name }: { name: string }): void {
    setTheme(name);
  }

  setFontFamily({ fontFamily }: { fontFamily: string }): void {
    setFontFamily(fontFamily);
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

  setShowInvisibles({ enabled }: { enabled: boolean }): void {
    setShowInvisibles(enabled);
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

  setDefaultLineBreak({ lineBreak }: { lineBreak?: string }): void {
    setDefaultLineBreak(lineBreak);
  }

  setTabKeyBehavior({ behavior }: { behavior: TabKeyBehavior }): void {
    setTabKeyBehavior(behavior);
  }

  setIndentUnit({ unit }: { unit: string }): void {
    setIndentUnit(unit);
  }
}
