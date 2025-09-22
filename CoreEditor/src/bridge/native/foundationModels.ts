import { NativeModule } from '../nativeModule';

export interface LanguageModelGenerationOptions {
  sampling?: LanguageModelSampling;
  temperature?: number;
  maximumResponseTokens?: CodeGen_Int;
}

export type LanguageModelSampling = {
  greedy?: boolean;
  top_k?: CodeGen_Int;
  top_p?: number;
  seed?: CodeGen_UInt64;
};

/**
 * @shouldExport true
 * @invokePath foundationModels
 * @bridgeName NativeBridgeFoundationModels
*/
export interface NativeModuleFoundationModels extends NativeModule {
  availability(): Promise<string>;
  createSession(options?: { instructions?: string }): Promise<string | undefined>;
  isResponding({ sessionID }: { sessionID?: string }): Promise<boolean>;
  respondTo(args: { sessionID?: string; prompt: string; options?: LanguageModelGenerationOptions }): Promise<string>;
  streamResponseTo(args: { sessionID?: string; streamID: string; prompt: string; options?: LanguageModelGenerationOptions }): void;
}
