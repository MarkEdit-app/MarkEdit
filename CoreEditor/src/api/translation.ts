import { TranslationService, TranslationResponse } from 'markedit-api';

/**
 * TranslationService implementation to leverage the system translate capability.
 */
export class Translator implements TranslationService {
  async translate(text: string, languages?: { from?: string; to?: string }): Promise<TranslationResponse> {
    const response = await window.nativeModules.translation.translate({ text, ...languages });
    const parsed = JSON.parse(response) ?? {};
    if (typeof parsed.text === 'string') {
      return { succeeded: true, text: parsed.text };
    } else {
      return { succeeded: false, error: parsed.error };
    }
  }
}
