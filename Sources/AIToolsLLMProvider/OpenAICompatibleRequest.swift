//
//  OpenAICompatibleRequest.swift
//  AIToolsLLMProvider
//
//  Created by Philippe Weidmann on 09.06.2026.
//

import Foundation

struct OpenAICompatibleRequest {
    let model: String
    let messages: [Message]
    let stream: Bool = true
    let responseFormat: ResponseFormat?

    init(model: String, messages: [Message], responseFormat: ResponseFormat? = nil) {
        self.model = model
        self.messages = messages
        self.responseFormat = responseFormat
    }
}

enum Role: String {
    case system
    case user
    case assistant
    case tool
}

struct ResponseFormat {
    let type: String
    let jsonSchema: JSONSchema?
}

struct JSONSchema {
    let name: String
    let strict: Bool
    let schema: [String: Any]
}

struct ToolCallFunction {
    let name: String
    let arguments: String
}

struct ToolCall {
    let id: String
    let type: String = "function"
    let function: ToolCallFunction
}

struct Message {
    let role: Role
    let content: String?
    let toolCalls: [ToolCall]?
    let toolCallId: String?

    init(role: Role, content: String? = nil, toolCalls: [ToolCall]? = nil, toolCallId: String? = nil) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallId = toolCallId
    }
}

// MARK: - Dictionary conversion for JSONSerialization

extension OpenAICompatibleRequest {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "model": model,
            "messages": messages.map { $0.toDictionary() },
            "stream": stream
        ]
        if let responseFormat {
            dict["response_format"] = responseFormat.toDictionary()
        }
        return dict
    }
}

extension Message {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["role": role.rawValue]
        if let content {
            dict["content"] = content
        }
        if let toolCalls, !toolCalls.isEmpty {
            dict["tool_calls"] = toolCalls.map { $0.toDictionary() }
        }
        if let toolCallId {
            dict["tool_call_id"] = toolCallId
        }
        return dict
    }
}

extension ToolCall {
    func toDictionary() -> [String: Any] {
        return [
            "id": id,
            "type": type,
            "function": function.toDictionary()
        ]
    }
}

extension ToolCallFunction {
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "arguments": arguments
        ]
    }
}

extension ResponseFormat {
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = ["type": type]
        if let jsonSchema {
            dict["json_schema"] = jsonSchema.toDictionary()
        }
        return dict
    }
}

extension JSONSchema {
    func toDictionary() -> [String: Any] {
        return [
            "name": name,
            "strict": strict,
            "schema": schema
        ]
    }
}
