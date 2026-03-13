import Foundation

struct ParsedResponse {
    let chat: String
    let prompt: String?
}

enum ResponseParser {
    static let delimiter = "---PROMPT---"

    static func parse(_ raw: String) -> ParsedResponse {
        guard let range = raw.range(of: delimiter) else {
            return ParsedResponse(chat: raw.trimmingCharacters(in: .whitespacesAndNewlines), prompt: nil)
        }

        let chatPart = String(raw[raw.startIndex..<range.lowerBound])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let promptPart = String(raw[range.upperBound...])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return ParsedResponse(
            chat: chatPart,
            prompt: promptPart.isEmpty ? nil : promptPart
        )
    }
}
