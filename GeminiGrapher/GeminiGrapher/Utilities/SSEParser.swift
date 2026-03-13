import Foundation

enum SSEParser {
    static func parseContentDelta(_ line: String) -> String? {
        guard line.hasPrefix("data: ") else { return nil }

        let payload = String(line.dropFirst(6))
        guard payload != "[DONE]" else { return nil }

        guard let data = payload.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let delta = choices.first?["delta"] as? [String: Any],
              let content = delta["content"] as? String
        else {
            return nil
        }

        return content
    }
}
