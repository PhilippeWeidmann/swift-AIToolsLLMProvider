import Testing
import FoundationModels
@testable import AIToolsLLMProvider

private let defaultModel = AIToolsModel(
    modelId: .gemma431BIt,
    productId: 0,
    apiKey: ""
)

// MARK: – Basic string response

@Test func basicStringResponse() async throws {
    let session = LanguageModelSession(model: defaultModel)
    let response = try await session.respond(to: "Hello")
    print("Response: \(response.content)")
}

// MARK: – Structured output with @Generable

@Generable(description: "A simple fact produced by the model")
private struct Fact {
    @Guide(description: "An interesting fact")
    var text: String
}

@Test func structuredOutputWithGenerable() async throws {
    let session = LanguageModelSession(model: defaultModel)
    let response = try await session.respond(
        to: "Tell me one interesting fact about the Swift programming language.",
        generating: Fact.self
    )
    print("Fact: \(response.content.text)")
}

// MARK: – Streaming response

@Test func streamingResponse() async throws {
    let session = LanguageModelSession(model: defaultModel)
    let stream = session.streamResponse(to: "Count from 1 to 5.")

    var text = ""
    for try await snapshot in stream {
        text = snapshot.content
        print("Snapshot: \(snapshot.content)")
    }

    print("Final text: \(text)")
}

// MARK: – Generation options

@Test func generationOptions() async throws {
    let session = LanguageModelSession(model: defaultModel)
    let options = GenerationOptions(
        temperature: 0.1,
        maximumResponseTokens: 50
    )
    let response = try await session.respond(
        to: "Summarize the Swift concurrency model in one sentence.",
        options: options
    )
    print("Response: \(response.content)")
}

// MARK: – Tool calling

private struct WeatherTool: Tool {
    let name = "get_weather"
    let description = "Returns the current weather for a given city."

    @Generable
    struct Arguments {
        @Guide(description: "The city name")
        var city: String
    }

    func call(arguments: Arguments) async throws -> String {
        return "The weather in \(arguments.city) is sunny and 25C."
    }
}

@Test func toolCalling() async throws {
    let session = LanguageModelSession(
        model: defaultModel,
        tools: [WeatherTool()]
    )

    let response = try await session.respond(
        to: "What is the weather in Paris?"
    )

    print("Response: \(response.content)")
}
