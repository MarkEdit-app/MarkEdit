import { WebModule } from '../webModule';
import { connect, disconnect, completeOAuth } from '../../modules/grammarly';

/**
 * @shouldExport true
 * @invokePath grammarly
 * @overrideModuleName WebBridgeGrammarly
 */
export interface WebModuleGrammarly extends WebModule {
  connect({ clientID, redirectURI }: { clientID: string; redirectURI: string }): void;
  disconnect(): void;
  completeOAuth({ url }: { url: string }): void;
}

export class WebModuleGrammarlyImpl implements WebModuleGrammarly {
  connect({ clientID, redirectURI }: { clientID: string; redirectURI: string }): void {
    connect(clientID, redirectURI);
  }

  disconnect(): void {
    disconnect();
  }

  completeOAuth({ url }: { url: string }): void {
    completeOAuth(url);
  }
}
