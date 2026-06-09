import Foundation

struct OpenAIStreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
            let toolCalls: [DeltaToolCall]?
            let reasoningContent: String?
        }

        struct DeltaToolCall: Decodable {
            let index: Int
            let id: String?
            let type: String?
            let function: DeltaToolCallFunction?
        }

        struct DeltaToolCallFunction: Decodable {
            let name: String?
            let arguments: String?
        }

        let delta: Delta
        let finishReason: String?
    }

    struct Usage: Decodable {
        let promptTokens: Int?
        let completionTokens: Int?
    }

    let choices: [Choice]
    let usage: Usage?
}
