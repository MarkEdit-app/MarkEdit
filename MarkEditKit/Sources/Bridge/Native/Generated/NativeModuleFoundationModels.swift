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
      return await streamResponseTo(parameters: parameters)
    default:
      return nil
    }
  }

  private func availability(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var modelName: String

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        modelName = try container.value("modelName")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.availability(modelName: message.modelName)
    return .success(result)
  }

  private func createSession(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var modelName: String
      var instructions: String?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        modelName = try container.value("modelName")
        instructions = try container.value("instructions")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.createSession(modelName: message.modelName, instructions: message.instructions)
    return .success(result)
  }

  private func isResponding(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var sessionID: String?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        sessionID = try container.value("sessionID")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.isResponding(sessionID: message.sessionID)
    return .success(result)
  }

  private func respondTo(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var sessionID: String?
      var prompt: String
      var options: LanguageModelGenerationOptions?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        sessionID = try container.value("sessionID")
        prompt = try container.value("prompt")
        options = try container.value("options")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.respondTo(sessionID: message.sessionID, prompt: message.prompt, options: message.options)
    return .success(result)
  }

  private func streamResponseTo(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var sessionID: String?
      var streamID: String
      var prompt: String
      var options: LanguageModelGenerationOptions?

      init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: BridgeFieldKey.self)
        sessionID = try container.value("sessionID")
        streamID = try container.value("streamID")
        prompt = try container.value("prompt")
        options = try container.value("options")
      }
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    module.streamResponseTo(sessionID: message.sessionID, streamID: message.streamID, prompt: message.prompt, options: message.options)
    return .success(nil)
  }
}

public struct LanguageModelGenerationOptions: Decodable {
  public var sampling: LanguageModelSampling?
  public var temperature: Double?
  public var maximumResponseTokens: Int?

  public init(sampling: LanguageModelSampling?, temperature: Double?, maximumResponseTokens: Int?) {
    self.sampling = sampling
    self.temperature = temperature
    self.maximumResponseTokens = maximumResponseTokens
  }

  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: BridgeFieldKey.self)
    sampling = try container.value("sampling")
    temperature = try container.value("temperature")
    maximumResponseTokens = try container.value("maximumResponseTokens")
  }
}

public struct LanguageModelSampling: Decodable {
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
