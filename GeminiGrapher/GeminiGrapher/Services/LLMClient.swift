import Foundation

class LLMClient {
    let baseURL: String

    var modelsURL: URL {
        URL(string: "\(baseURL)/v1/models")!
    }

    private var completionsURL: URL {
        URL(string: "\(baseURL)/v1/chat/completions")!
    }

    init(baseURL: String = "http://localhost:8317") {
        self.baseURL = baseURL
    }

    func buildRequest(messages: [[String: String]], model: String) throws -> URLRequest {
        var request = URLRequest(url: completionsURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "stream": true,
        ]
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        return request
    }

    func streamCompletion(
        messages: [[String: String]],
        model: String
    ) -> AsyncThrowingStream<String, Error> {
        AsyncThrowingStream { continuation in
            Task {
                do {
                    let request = try buildRequest(messages: messages, model: model)
                    let (bytes, response) = try await URLSession.shared.bytes(for: request)
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200
                    else {
                        let statusCode = (response as? HTTPURLResponse)?.statusCode ?? -1
                        continuation.finish(throwing: LLMError.httpError(statusCode))
                        return
                    }
                    for try await line in bytes.lines {
                        if let content = SSEParser.parseContentDelta(line) {
                            continuation.yield(content)
                        }
                    }
                    continuation.finish()
                } catch {
                    continuation.finish(throwing: error)
                }
            }
        }
    }

    func fetchModels() async throws -> [String] {
        let (data, _) = try await URLSession.shared.data(from: modelsURL)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        let models = json?["data"] as? [[String: Any]] ?? []
        return models.compactMap { $0["id"] as? String }
    }
}

enum LLMError: LocalizedError {
    case httpError(Int)
    var errorDescription: String? {
        switch self {
        case .httpError(let code):
            return "HTTP error \(code) from vibeproxy"
        }
    }
}
