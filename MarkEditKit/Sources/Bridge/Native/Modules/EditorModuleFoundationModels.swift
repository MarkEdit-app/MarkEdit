//
//  EditorModuleFoundationModels.swift
//
//  Created by cyan on 9/18/25.
//

import Foundation
import FoundationModels
import MarkEditCore

@MainActor
public protocol EditorModuleFoundationModelsDelegate: AnyObject {
  func editorFoundationModelsApplyStreamUpdate(
    _ sender: EditorModuleFoundationModels,
    streamID: String,
    response: LanguageModelResponse
  )
}

public final class EditorModuleFoundationModels: NativeModuleFoundationModels {
  private weak var delegate: EditorModuleFoundationModelsDelegate?

  public init(delegate: EditorModuleFoundationModelsDelegate) {
    self.delegate = delegate
  }

  public func availability() async -> String {
    defaultModelAvailability.jsonEncoded
  }

  public func createSession(instructions: String?) async -> String? {
    guard #available(macOS 26.0, *) else {
      return nil
    }

    let identifier = UUID().uuidString
    let session = LanguageModelSession(instructions: instructions)

    sessionPool[identifier] = session
    return identifier
  }

  public func isResponding(sessionID: String?) async -> Bool {
    guard #available(macOS 26.0, *), let session = session(with: sessionID) else {
      return false
    }

    return session.isResponding
  }

  public func respondTo(
    sessionID: String?,
    prompt: String,
    options: LanguageModelGenerationOptions?
  ) async -> String {
    let encode: (String?, String?, Bool) -> String = { content, error, done in
      LanguageModelResponse(
        content: content,
        error: error,
        done: done
      ).jsonEncoded
    }

    guard #available(macOS 26.0, *), let session = session(with: sessionID) else {
      return encode(nil, "Model Unavailable", true)
    }

    do {
      let response = try await session.respond(
        to: prompt,
        options: GenerationOptions(options)
      )

      return encode(response.content, nil, true)
    } catch {
      return encode(nil, error.localizedDescription, true)
    }
  }

  public func streamResponseTo(
    sessionID: String?,
    streamID: String,
    prompt: String,
    options: LanguageModelGenerationOptions?
  ) {
    let didReceive: (String?, String?, Bool) -> Void = { [weak self] content, error, done in
      guard let self else {
        return
      }

      DispatchQueue.main.async {
        let response = LanguageModelResponse(
          content: content,
          error: error,
          done: done
        )

        self.delegate?.editorFoundationModelsApplyStreamUpdate(
          self,
          streamID: streamID,
          response: response
        )
      }
    }

    guard #available(macOS 26.0, *), let session = session(with: sessionID) else {
      return didReceive(nil, "Model Unavailable", true)
    }

    Task {
      do {
        let stream = session.streamResponse(
          to: prompt,
          options: GenerationOptions(options)
        )

        for try await snapshot in stream {
          didReceive(snapshot.content, nil, false)
        }

        let response = try await stream.collect()
        didReceive(response.content, nil, true)
      } catch {
        didReceive(nil, error.localizedDescription, true)
      }
    }
  }

  // MARK: - Private

  private var defaultModelAvailability: LanguageModelAvailability {
    guard #available(macOS 26.0, *) else {
      return LanguageModelAvailability(isAvailable: false, unavailableReason: "Unsupported OS Version")
    }

    switch SystemLanguageModel.default.availability {
    case .available:
      return LanguageModelAvailability(isAvailable: true, unavailableReason: nil)
    case .unavailable(.deviceNotEligible):
      return LanguageModelAvailability(isAvailable: false, unavailableReason: "Device Not Eligible")
    case .unavailable(.appleIntelligenceNotEnabled):
      return LanguageModelAvailability(isAvailable: false, unavailableReason: "Apple Intelligence Not Enabled")
    case .unavailable(.modelNotReady):
      return LanguageModelAvailability(isAvailable: false, unavailableReason: "Model Not Ready")
    @unknown default:
      return LanguageModelAvailability(isAvailable: false, unavailableReason: "Unknown")
    }
  }

  // [macOS 26] Change the value type to LanguageModelSession
  private var sessionPool = [String: AnyObject]()

  @available(macOS 26.0, *)
  private func session(with sessionID: String?) -> LanguageModelSession? {
    guard let sessionID, let session = (sessionPool[sessionID] as? LanguageModelSession) else {
      return nil
    }

    return session
  }
}

// MARK: - Private

@available(macOS 26.0, *)
private extension GenerationOptions {
  init(_ options: LanguageModelGenerationOptions?) {
    self.init(
      sampling: SamplingMode(options?.sampling),
      temperature: options?.temperature,
      maximumResponseTokens: options?.maximumResponseTokens
    )
  }
}

@available(macOS 26.0, *)
private extension GenerationOptions.SamplingMode {
  init?(_ sampling: LanguageModelSampling?) {
    if sampling?.greedy == true {
      self = .greedy
    } else if let top_k = sampling?.top_k {
      self = .random(top: top_k, seed: sampling?.seed)
    } else if let top_p = sampling?.top_p {
      self = .random(probabilityThreshold: top_p, seed: sampling?.seed)
    } else {
      return nil
    }
  }
}
