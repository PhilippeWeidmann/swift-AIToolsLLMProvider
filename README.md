# AIToolsLLMProvider

A Swift package that brings Infomaniak AI models to Apple's [`FoundationModels`](https://developer.apple.com/documentation/foundationmodels) framework. It implements a full `LanguageModel` provider, so you can use it directly with `LanguageModelSession`, `Tool` calling, `@Generable` structured output, streaming, and everything else `FoundationModels` offers.

> **⚠️ Beta Software**
>
> This package is in **beta** and is provided as-is. The underlying platforms (iOS 27, macOS 27, visionOS 27, watchOS 27) are also currently in beta, so APIs may change and things may break between releases.
>
> **Not all `FoundationModels` features are supported yet.** The package currently implements the most common capabilities, but coverage is not exhaustive.
>
> **Security notice:** Your API key is compiled into the binary and transmitted in `Authorization` headers. At this time, the key can potentially be intercepted. If there is enough demand for this package, we plan to gradually add **certificate pinning** and **DeviceCheck** support to make API key theft significantly harder.

## Features

- **Native FoundationModels integration** — Drop-in `LanguageModel` implementation for `LanguageModelSession`.
- **Streaming** — Real-time streaming of tokens, reasoning content, and usage stats.
- **Tool calling** — Register `Tool` protocols and let the model invoke them automatically.
- **Structured output** — Use `@Generable` models for type-safe JSON responses.
- **Reasoning support** — Seamlessly handles reasoning content from supported models.
- **OpenAI-compatible endpoint** — Proxies to Infomaniak's OpenAI-compatible Chat Completions API.

## Supported Models

| Model | Identifier |
|-------|------------|
| Swiss AI Apertus 70B Instruct | `swiss-ai/Apertus-70B-Instruct-2509` |
| Mistral Ministral 3 14B Instruct | `mistralai/Ministral-3-14B-Instruct-2512` |
| Qwen 3.5 122B | `Qwen/Qwen3.5-122B-A10B-FP8` |
| Google Gemma 4 31B | `google/gemma-4-31B-it` |
| Moonshot Kimi K2.6 | `moonshotai/Kimi-K2.6` |

## Requirements

- iOS 27.0+ / macOS 27.0+ / visionOS 27.0+ / watchOS 27.0+
- Swift 6.4+
- An [Infomaniak AI Tools](https://www.infomaniak.com/en/hosting/ai-services) product and API key

## Installation

Add `AIToolsLLMProvider` as a dependency in your `Package.swift`:

```swift
// swift-tools-version:6.4
import PackageDescription

let package = Package(
    name: "MyApp",
    platforms: [.macOS(.v27), .iOS(.v27)],
    dependencies: [
        .package(url: "https://github.com/your-org/AIToolsLLMProvider.git", from: "1.0.0")
    ],
    targets: [
        .executableTarget(
            name: "MyApp",
            dependencies: ["AIToolsLLMProvider"]
        )
    ]
)
```

Or add it directly in Xcode: **File > Add Package Dependencies...** and paste the repository URL.

## Quick Start

Import the package, create a model with your Infomaniak credentials, and start a `LanguageModelSession`:

### Basic Prompt

```swift
import AIToolsLLMProvider
import FoundationModels

let model = AIToolsModel(
    modelId: .gemma431BIt,   // or .kimi266, .apertus70BInstruct2509, ...
    productId: 123,          // Your Infomaniak AI product ID
    apiKey: "your-api-key"   // Your Infomaniak API key
)

let session = LanguageModelSession(model: model)
let response = try await session.respond(to: "What is Generative AI?")
print(response.content)
```

### Streaming Responses

```swift
let stream = session.streamResponse(to: "Count from 1 to 5.")

for try await snapshot in stream {
    print(snapshot.content, terminator: "")
}
```

### Structured Output with `@Generable`

```swift
@Generable(description: "A fun fact about anything")
struct Fact {
    @Guide(description: "The interesting fact")
    var text: String
}

let response = try await session.respond(
    to: "Tell me a fun fact about Swift",
    generating: Fact.self
)
print(response.content.text)   // Type-safe Fact struct
```

### Tool Calling

```swift
struct WeatherTool: Tool {
    let name = "get_weather"
    let description = "Returns the current weather for a city."

    @Generable
    struct Arguments {
        @Guide(description: "City name")
        var city: String
    }

    func call(arguments: Arguments) async throws -> String {
        return "The weather in \(arguments.city) is sunny and 25C."
    }
}

let toolSession = LanguageModelSession(
    model: model,
    tools: [WeatherTool()]
)
let response = try await toolSession.respond(to: "What's the weather in Paris?")
print(response.content)
```

### Generation Options

```swift
let options = GenerationOptions(
    temperature: 0.2,
    maximumResponseTokens: 256
)

let response = try await session.respond(
    to: "Explain async/await in one sentence.",
    options: options
)
```

## How it works

`AIToolsLLMProvider` conforms to Apple's `LanguageModel` protocol and translates `FoundationModels` requests into Infomaniak's [OpenAI-compatible chat completions API](https://developer.infomaniak.com/docs/api/post/2/ai/%7Bproduct_id%7D/openai/v1/chat/completions). It handles:

- **Streaming** via Server-Sent Events (SSE)
- **JSON schema generation** for `@Generable` structured output
- **Tool call buffering** across streamed chunks
- **System/user/assistant/tool message roles** properly mapped

Running a request is as simple as using any other `FoundationModels` provider—no extra networking code required.

## Example Project

You can explore the included tests for working examples of every feature:

```bash
swift test
```

The test file `Tests/AIToolsLLMProviderTests/AIToolsLLMProviderTests.swift` demonstrates:
- basic string responses
- `@Generable` structured output
- streaming
- `GenerationOptions`
- `Tool` invocation

## License

AIToolsLLMProvider is available under the Apache 2.0 license. See [LICENSE](LICENSE) for more information.
