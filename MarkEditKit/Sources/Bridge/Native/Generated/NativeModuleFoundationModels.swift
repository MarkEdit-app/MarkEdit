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
  func availability() async -> String
  func createSession(instructions: String?) async -> String?
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
  lazy var methods: [String: NativeMethod] = [
    "availability": { [weak self] in
      await self?.availability(parameters: $0)
    },
    "createSession": { [weak self] in
      await self?.createSession(parameters: $0)
    },
    "isResponding": { [weak self] in
      await self?.isResponding(parameters: $0)
    },
    "respondTo": { [weak self] in
      await self?.respondTo(parameters: $0)
    },
    "streamResponseTo": { [weak self] in
      await self?.streamResponseTo(parameters: $0)
    },
  ]

  private let module: NativeModuleFoundationModels
  private lazy var decoder = JSONDecoder()

  init(_ module: NativeModuleFoundationModels) {
    self.module = module
  }

  private func availability(parameters: Data) async -> Result<Any?, Error>? {
    let result = await module.availability()
    return .success(result)
  }

  private func createSession(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var instructions: String?
    }

    let message: Message
    do {
      message = try decoder.decode(Message.self, from: parameters)
    } catch {
      Logger.assertFail("Failed to decode parameters: \(parameters)")
      return .failure(error)
    }

    let result = await module.createSession(instructions: message.instructions)
    return .success(result)
  }

  private func isResponding(parameters: Data) async -> Result<Any?, Error>? {
    struct Message: Decodable {
      var sessionID: String?
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

public struct LanguageModelGenerationOptions: Decodable, Equatable {
  public var sampling: LanguageModelSampling?
  public var temperature: Double?
  public var maximumResponseTokens: Int?

  public init(sampling: LanguageModelSampling?, temperature: Double?, maximumResponseTokens: Int?) {
    self.sampling = sampling
    self.temperature = temperature
    self.maximumResponseTokens = maximumResponseTokens
  }
}

public struct LanguageModelSampling: Decodable, Equatable {
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
}
