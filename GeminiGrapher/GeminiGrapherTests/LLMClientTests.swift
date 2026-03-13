import Testing
import Foundation
@testable import GeminiGrapher

@Suite("LLMClient")
struct LLMClientTests {
    @Test("builds correct URLRequest")
    func buildsRequest() throws {
        let client = LLMClient(baseURL: "http://localhost:8317")
        let messages: [[String: String]] = [
            ["role": "system", "content": "You are helpful"],
            ["role": "user", "content": "Hello"],
        ]
        let request = try client.buildRequest(messages: messages, model: "claude-sonnet-4-6")
        #expect(request.url?.absoluteString == "http://localhost:8317/v1/chat/completions")
        #expect(request.httpMethod == "POST")
        #expect(request.value(forHTTPHeaderField: "Content-Type") == "application/json")
        let body = try JSONSerialization.jsonObject(with: request.httpBody!) as! [String: Any]
        #expect(body["model"] as? String == "claude-sonnet-4-6")
        #expect(body["stream"] as? Bool == true)
        #expect((body["messages"] as? [[String: String]])?.count == 2)
    }

    @Test("fetches models list")
    func modelsEndpoint() {
        let client = LLMClient(baseURL: "http://localhost:8317")
        let url = client.modelsURL
        #expect(url.absoluteString == "http://localhost:8317/v1/models")
    }
}
