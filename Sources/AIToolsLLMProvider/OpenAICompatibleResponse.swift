
struct OpenAIStreamChunk: Decodable {
    struct Choice: Decodable {
        struct Delta: Decodable {
            let content: String?
        }

        let delta: Delta
    }

    struct Usage: Decodable {
        let promptTokens: Int?
        let completionTokens: Int?
    }

    let choices: [Choice]
    let usage: Usage?
}
