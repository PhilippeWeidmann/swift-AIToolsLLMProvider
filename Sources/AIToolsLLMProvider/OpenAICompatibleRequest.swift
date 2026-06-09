//
//  OpenAICompatibleRequest.swift
//  AIToolsLLMProvider
//
//  Created by Philippe Weidmann on 09.06.2026.
//

import Foundation

struct OpenAICompatibleRequest: Encodable {
    let model: String
    let messages: [Message]
    let stream: Bool = true
}

enum Role: String, Encodable {
    case system
    case user
    case assistant
    case tool
}

struct ToolCallFunction: Encodable {
    let name: String
    let arguments: String
}

struct ToolCall: Encodable {
    let id: String
    let type: String = "function"
    let function: ToolCallFunction
}

struct Message: Encodable {
    let role: Role
    let content: String?
    let toolCalls: [ToolCall]?
    let toolCallId: String?

    enum CodingKeys: String, CodingKey {
        case role
        case content
        case toolCalls = "tool_calls"
        case toolCallId = "tool_call_id"
    }

    init(role: Role, content: String? = nil, toolCalls: [ToolCall]? = nil, toolCallId: String? = nil) {
        self.role = role
        self.content = content
        self.toolCalls = toolCalls
        self.toolCallId = toolCallId
    }
}
