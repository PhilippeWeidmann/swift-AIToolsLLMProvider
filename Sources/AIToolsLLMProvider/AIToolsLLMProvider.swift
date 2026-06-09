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
                break
            case let .prompt(prompt):
                for segment in prompt.segments {
                    switch segment {
                    case let .text(textSegment):
                        requestMessages.append(Message(role: .user, content: textSegment.content))
                    case let .structure(structuredSegment):
                        break
                    case let .attachment(attachmentSegment):
                        break
                    case let .custom(customSegment):
                        break
                    @unknown default:
                        break
                    }
                }
            case let .toolCalls(toolCalls):
                break
            case let .toolOutput(toolOutput):
                break
            case let .response(response):
                break
            case let .reasoning(reasoning):
                break
            @unknown default:
                break
            }
        }

        let openAIRequest = OpenAICompatibleRequest(model: model.modelId.rawValue, messages: requestMessages)

        let url = URL(string: "https://api.infomaniak.com/2/ai/\(configuration.productId)/openai/v1/chat/completions")!
        var urlRequest = URLRequest(url: url)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(configuration.apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(openAIRequest)

        let (bytes, response) = try await URLSession.shared.bytes(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse,
              (200 ..< 300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }

        let entryID = UUID().uuidString
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase

        for try await line in bytes.lines {
            guard line.hasPrefix("data: ") else { continue }
            let jsonString = String(line.dropFirst(6))
            guard jsonString != "[DONE]" else { break }
            guard let data = jsonString.data(using: .utf8),
                  let chunk = try? decoder.decode(OpenAIStreamChunk.self, from: data),
                  let content = chunk.choices.first?.delta.content else { continue }
            await channel.send(.response(entryID: entryID, action: .appendText(content, segmentID: nil, tokenCount: 0)))
        }
    }
}
