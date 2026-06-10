import Foundation
import FoundationModels

public enum AIToolsModelId: String, Sendable {
    case apertus70BInstruct2509 = "swiss-ai/Apertus-70B-Instruct-2509"
    case ministral314BInstruct2512 = "mistralai/Ministral-3-14B-Instruct-2512"
    case qwen35122BA10BFP8 = "Qwen/Qwen3.5-122B-A10B-FP8"
    case gemma431BIt = "google/gemma-4-31B-it"
    case kimi266 = "moonshotai/Kimi-K2.6"
}

public struct AIToolsModel: LanguageModel {
    public typealias Executor = AIToolsModelExecutor

    let modelId: AIToolsModelId
    private let productId: Int
    private let apiKey: String

    public var capabilities: LanguageModelCapabilities {
        LanguageModelCapabilities(capabilities: [
            .toolCalling, .guidedGeneration, .reasoning
        ])
    }

    public var executorConfiguration: Executor.Configuration {
        Executor.Configuration(productId: productId, apiKey: apiKey)
    }

    public init(modelId: AIToolsModelId, productId: Int, apiKey: String) {
        self.modelId = modelId
        self.productId = productId
        self.apiKey = apiKey
    }
}

public struct AIToolsModelExecutor: LanguageModelExecutor {
    public typealias Model = AIToolsModel

    public struct Configuration: Hashable, Sendable {
        let productId: Int
        let apiKey: String
    }

    private let configuration: Configuration

    public init(configuration: Configuration) throws {
        self.configuration = configuration
    }

    public func respond(
        to request: LanguageModelExecutorGenerationRequest,
        model: AIToolsModel,
        streamingInto channel: LanguageModelExecutorGenerationChannel
    ) async throws {
        var requestMessages = [Message]()

        for entry in request.transcript {
            switch entry {
            case let .instructions(instructions):
                let text = instructions.segments.compactMap { segment -> String? in
                    if case let .text(textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined(separator: "")
                if !text.isEmpty {
                    requestMessages.append(Message(role: .system, content: text))
                }
            case let .prompt(prompt):
                var parts = [String]()
                for segment in prompt.segments {
                    switch segment {
                    case let .text(textSegment):
                        parts.append(textSegment.content)
                    case let .structure(structuredSegment):
                        parts.append(structuredSegment.content.jsonString)
                    case .attachment, .custom:
                        break
                    @unknown default:
                        break
                    }
                }
                let content = parts.joined(separator: "")
                if !content.isEmpty {
                    requestMessages.append(Message(role: .user, content: content))
                }
            case let .toolCalls(toolCalls):
                let mapped = toolCalls.map { tc in
                    ToolCall(
                        id: tc.id,
                        function: .init(name: tc.toolName, arguments: tc.arguments.jsonString)
                    )
                }
                requestMessages.append(Message(role: .assistant, toolCalls: mapped))
            case let .toolOutput(toolOutput):
                let text = toolOutput.segments.compactMap { segment -> String? in
                    if case let .text(textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined(separator: "")
                requestMessages.append(Message(
                    role: .tool,
                    content: text,
                    toolCallId: toolOutput.id
                ))
            case let .response(response):
                let text = response.segments.compactMap { segment -> String? in
                    if case let .text(textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined(separator: "")
                if !text.isEmpty {
                    requestMessages.append(Message(role: .assistant, content: text))
                }
            case let .reasoning(reasoning):
                let text = reasoning.segments.compactMap { segment -> String? in
                    if case let .text(textSegment) = segment {
                        return textSegment.content
                    }
                    return nil
                }.joined(separator: "")
                if !text.isEmpty {
                    requestMessages.append(Message(role: .assistant, content: text))
                }
            @unknown default:
                break
            }
        }

        var responseFormat: ResponseFormat?

        if let schema = request.schema {
            let schemaEncoder = JSONEncoder()
            let schemaData = try schemaEncoder.encode(schema)
            let schemaObject = try JSONSerialization.jsonObject(with: schemaData)

            if let schemaDict = schemaObject as? [String: Any] {
                responseFormat = ResponseFormat(
                    type: "json_schema",
                    jsonSchema: JSONSchema(
                        name: "response",
                        strict: true,
                        schema: schemaDict
                    )
                )
            }

            let includeInPrompt = request.contextOptions.includeSchemaInPrompt ?? true
            if includeInPrompt, let schemaString = String(data: schemaData, encoding: .utf8) {
                if let firstSystemIndex = requestMessages.firstIndex(where: { $0.role == .system }) {
                    let existingContent = requestMessages[firstSystemIndex].content ?? ""
                    requestMessages[firstSystemIndex] = Message(
                        role: .system,
                        content: existingContent + "\n\nThe response must conform to the following JSON schema:\n" + schemaString
                    )
                } else {
                    requestMessages.insert(
                        Message(role: .system, content: "The response must conform to the following JSON schema:\n" + schemaString),
                        at: 0
                    )
                }
            }
        }

        let openAIRequest = OpenAICompatibleRequest(
            model: model.modelId.rawValue,
            messages: requestMessages,
            responseFormat: responseFormat
        )

        let url = URL(string: "https://api.infomaniak.com/2/ai/\(configuration.productId)/openai/v1/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: openAIRequest.toDictionary())

        let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ..< 300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let entryID = UUID().uuidString
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        var toolCallBuffers: [Int: PartialToolCall] = [:]

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6))
            guard jsonString != "[DONE]" else { break }
            guard let data = jsonString.data(using: .utf8),
                  let chunk = try? decoder.decode(OpenAIStreamChunk.self, from: data) else { continue }

            if let usage = chunk.usage,
               let promptTokens = usage.promptTokens,
               let completionTokens = usage.completionTokens {
                let usageEvent = LanguageModelExecutorGenerationChannel.Usage(
                    input: .init(totalTokenCount: promptTokens, cachedTokenCount: 0),
                    output: .init(totalTokenCount: completionTokens, reasoningTokenCount: 0)
                )
                await channel.send(.response(entryID: entryID, action: .updateUsage(usageEvent)))
            }

            if let choice = chunk.choices.first {
                let delta = choice.delta

                if choice.finishReason != nil, !toolCallBuffers.isEmpty {
                    await flushToolCalls(buffers: toolCallBuffers, entryID: entryID, channel: channel)
                    toolCallBuffers.removeAll()
                }

                if let content = delta.content, !content.isEmpty {
                    await channel.send(.response(entryID: entryID, action: .appendText(content, segmentID: nil, tokenCount: 0)))
                }

                if let reasoning = delta.reasoningContent, !reasoning.isEmpty {
                    await channel.send(.reasoning(entryID: entryID, action: .appendText(reasoning, segmentID: nil, tokenCount: 0)))
                }

                if let toolCallDeltas = delta.toolCalls {
                    for toolCallDelta in toolCallDeltas {
                        let index = toolCallDelta.index
                        if toolCallBuffers[index] == nil {
                            toolCallBuffers[index] = PartialToolCall()
                        }
                        if let id = toolCallDelta.id {
                            toolCallBuffers[index]?.id = id
                        }
                        if let name = toolCallDelta.function?.name {
                            toolCallBuffers[index]?.name = name
                        }
                        if let args = toolCallDelta.function?.arguments {
                            toolCallBuffers[index]?.arguments.append(args)
                        }
                    }
                }
            }
        }

        if !toolCallBuffers.isEmpty {
            await flushToolCalls(buffers: toolCallBuffers, entryID: entryID, channel: channel)
        }
    }
}

private struct PartialToolCall {
    var id: String = ""
    var name: String = ""
    var arguments: String = ""
}

private func flushToolCalls(
    buffers: [Int: PartialToolCall],
    entryID: String,
    channel: LanguageModelExecutorGenerationChannel
) async {
    let sorted = buffers.sorted { $0.key < $1.key }
    for (_, partial) in sorted {
        guard !partial.id.isEmpty, !partial.name.isEmpty else { continue }
        await channel.send(.toolCalls(
            entryID: entryID,
            action: .toolCall(
                id: partial.id,
                name: partial.name,
                action: .appendArguments(partial.arguments, tokenCount: 0)
            )
        ))
    }
}
