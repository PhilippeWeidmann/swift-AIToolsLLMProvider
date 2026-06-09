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
}

struct Message: Encodable {
    let role: Role
    let content: String
}
