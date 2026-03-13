import Testing
import Foundation
@testable import GeminiGrapher

@Suite("PromptEngine")
struct PromptEngineTests {
    @Test("builds system prompt with all sections")
    func fullSystemPrompt() {
        let prompt = PromptEngine.buildSystemPrompt(
            preferences: "- cinematic lighting",
            feedback: "- too dark last time",
            currentPrompt: "A cyberpunk scene...",
            version: 2
        )
        #expect(prompt.contains("expert at crafting prompts for Gemini image generation"))
        #expect(prompt.contains("---PROMPT---"))
        #expect(prompt.contains("cinematic lighting"))
        #expect(prompt.contains("too dark last time"))
        #expect(prompt.contains("A cyberpunk scene..."))
        #expect(prompt.contains("version 2"))
    }

    @Test("shows None yet when no current prompt")
    func noCurrentPrompt() {
        let prompt = PromptEngine.buildSystemPrompt(preferences: "", feedback: "", currentPrompt: nil, version: 0)
        #expect(prompt.contains("None yet"))
    }

    @Test("builds message array from session messages")
    func buildsMessages() {
        let system = "System prompt here"
        let messages = [
            (role: "user", content: "Make it cinematic"),
            (role: "assistant", content: "Updated.\n\n---PROMPT---\nA cinematic scene..."),
        ]
        let result = PromptEngine.buildRequestMessages(
            systemPrompt: system,
            history: messages.map { (role: $0.role, content: $0.content) }
        )
        #expect(result.count == 3)
        #expect(result[0]["role"] == "system")
        #expect(result[1]["role"] == "user")
        #expect(result[2]["role"] == "assistant")
    }
}
