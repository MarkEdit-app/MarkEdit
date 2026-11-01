//
//  NativeModuleFoundationModels.swift
//
//  Generated using https://github.com/microsoft/ts-gyb
//
//  Don't modify this file manually, it's auto generated.
//
//  To make changes, edit template files under /CoreEditor/src/@codegen

import Foundation
import MarkEditCore

@MainActor
public protocol NativeModuleFoundationModels: NativeModule {
  func availability(modelName: String) async -> String
  func createSession(modelName: String, instructions: String?) async -> String?
  func isResponding(sessionID: String?) async -> Bool
  func respondTo(sessionID: String?, prompt: String, options: LanguageModelGenerationOptions?) async -> String
  func streamResponseTo(sessionID: String?, streamID: String, prompt: String, options: LanguageModelGenerationOptions?)
}

public extension NativeModuleFoundationModels {
  var bridge: NativeBridge { NativeBridgeFoundationModels(self) }
}

@MainActor
final class NativeBridgeFoundationModels: NativeBridge {
  static let name = "foundationModels"

  private let module: NativeModuleFoundationModels
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleFoundationModels) {
    self.module = module
  }

  func invoke(method: String, parameters: Data) async -> Result<Any?, Error>? {
    switch method {
    case "availability":
      return await availability(parameters: parameters)
    case "createSession":
      return await createSession(parameters: parameters)
    case "isResponding":
      return await isResponding(parameters: parameters)
    case "respondTo":
      return await respondTo(parameters: parameters)
    case "streamResponseTo":
      return streamResponseTo(parameters: parameters)
    default:
      return nil
    }
  }

  private func availability(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_modelName: String

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_modelName = try container.value("modelName")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.availability(modelName: parameter_modelName)
    return .success(result)
  }

  private func createSession(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_modelName: String
    let parameter_instructions: String?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_modelName = try container.value("modelName")
      parameter_instructions = try container.value("instructions")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.createSession(modelName: parameter_modelName, instructions: parameter_instructions)
    return .success(result)
  }

  private func isResponding(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_sessionID: String?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_sessionID = try container.value("sessionID")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.isResponding(sessionID: parameter_sessionID)
    return .success(result)
  }

  private func respondTo(parameters: Data) async -> Result<Any?, Error>? {
    let parameter_sessionID: String?
    let parameter_prompt: String
    let parameter_options: LanguageModelGenerationOptions?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_sessionID = try container.value("sessionID")
      parameter_prompt = try container.value("prompt")
      parameter_options = try container.value("options")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.respondTo(sessionID: parameter_sessionID, prompt: parameter_prompt, options: parameter_options)
    return .success(result)
  }

  private func streamResponseTo(parameters: Data) -> Result<Any?, Error>? {
    let parameter_sessionID: String?
    let parameter_streamID: String
    let parameter_prompt: String
    let parameter_options: LanguageModelGenerationOptions?

    do {
      let container = try decoder.decode(BridgeParameters.self, from: parameters).container
      parameter_sessionID = try container.value("sessionID")
      parameter_streamID = try container.value("streamID")
      parameter_prompt = try container.value("prompt")
      parameter_options = try container.value("options")
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.streamResponseTo(sessionID: parameter_sessionID, streamID: parameter_streamID, prompt: parameter_prompt, options: parameter_options)
    return .success(nil)
  }
}

public struct LanguageModelGenerationOptions: Decodable, Sendable {
  public var attachments: [String]?
  public var sampling: LanguageModelSampling?
  public var temperature: Double?
  public var maximumResponseTokens: Int?

  public init(attachments: [String]?, sampling: LanguageModelSampling?, temperature: Double?, maximumResponseTokens: Int?) {
    self.attachments = attachments
    self.sampling = sampling
    self.temperature = temperature
    self.maximumResponseTokens = maximumResponseTokens
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    attachments = try container.value("attachments")
    sampling = try container.value("sampling")
    temperature = try container.value("temperature")
    maximumResponseTokens = try container.value("maximumResponseTokens")
  }
}

public struct LanguageModelSampling: Decodable, Sendable {
  public var greedy: Bool?
  public var top_k: Int?
  public var top_p: Double?
  public var seed: UInt64?

  public init(greedy: Bool?, top_k: Int?, top_p: Double?, seed: UInt64?) {
    self.greedy = greedy
    self.top_k = top_k
    self.top_p = top_p
    self.seed = seed
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    greedy = try container.value("greedy")
    top_k = try container.value("top_k")
    top_p = try container.value("top_p")
    seed = try container.value("seed")
  }
}
