import { v4 as UUID } from 'uuid';
import { LanguageModel, LanguageModelGenerationOptions, LanguageModelResponse, LanguageModelStream } from 'markedit-api';
import { LanguageModelGenerationOptions as SimplifiedGenerationOptions } from '../bridge/native/foundationModels';

export function languageModel(): LanguageModel {
  // The only supported model at this time is Apple's Foundation Models
  //
  // https://developer.apple.com/documentation/FoundationModels
  const nativeModule = window.nativeModules.foundationModels;
  return {
    availability: async() => {
      const availability = await nativeModule.availability();
      return JSON.parse(availability);
    },
    createSession: async(options) => {
      const sessionID = await nativeModule.createSession(options);
      return {
        isResponding: () => nativeModule.isResponding({ sessionID }),
        respondTo: async(prompt, options) => {
          const response = await nativeModule.respondTo({
            sessionID,
            prompt,
            options: simply(options),
          });

          return JSON.parse(response);
        },
        streamResponseTo: (prompt, arg1, arg2) => {
          const streamID = UUID();
          const options = typeof arg1 === 'function' ? undefined : arg1;
          const stream = typeof arg1 === 'function' ? arg1 : arg2;
          if (typeof stream === 'function') {
            activeStreams.set(streamID, stream);
          }

          nativeModule.streamResponseTo({
            sessionID,
            streamID,
            prompt,
            options: simply(options),
          });
        },
      };
    },
  };
}

export function applyStreamUpdate(streamID: string, response: LanguageModelResponse) {
  const stream = activeStreams.get(streamID);
  if (stream !== undefined) {
    stream(response);
  }

  if (response.done) {
    activeStreams.delete(streamID);
  }
}

// Simplified types for native compatibility, ts-gyb struggles with complex typing
function simply(options?: LanguageModelGenerationOptions): SimplifiedGenerationOptions | undefined {
  if (options === undefined) {
    return undefined;
  }

  return {
    sampling: (() => {
      const sampling = options.sampling;
      switch (sampling?.mode) {
        case 'greedy': return { greedy: true };
        case 'top-k': return { top_k: sampling.value as CodeGen_Int, seed: sampling.seed as CodeGen_UInt64 };
        case 'top-p': return { top_p: sampling.value, seed: sampling.seed as CodeGen_UInt64 };
        default: return undefined;
      }
    })(),
    temperature: options.temperature,
    maximumResponseTokens: options.maximumResponseTokens as CodeGen_Int,
  };
}

const activeStreams = new Map<string, LanguageModelStream>();
