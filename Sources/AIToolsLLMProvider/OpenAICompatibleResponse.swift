//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//      http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing,
//  software distributed under the License is distributed on an
//  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
//  KIND, either express or implied.  See the License for the
//  specific language governing permissions and limitations
//  under the License.

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
