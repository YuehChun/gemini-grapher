import Foundation

enum PromptEngine {
    static func buildSystemPrompt(
        preferences: String,
        feedback: String,
        currentPrompt: String?,
        version: Int
    ) -> String {
        let promptSection = currentPrompt ?? "None yet"
        return """
        You are an expert at crafting prompts for Gemini image generation. \
        The user will describe what they want in conversational fragments. Your job:

        1. Understand their intent and ask clarifying questions when needed.
        2. Synthesize all fragments into a single, complete, natural-language prompt \
        optimized for Gemini image generation.
        3. When you produce or update a prompt, format your response as:
           - Your conversational reply first
           - Then the delimiter ---PROMPT--- on its own line
           - Then the complete prompt (not a diff — always the full text)
        4. If you only need to ask a question or discuss (no prompt update), omit the delimiter entirely.

        ## User's Style Preferences
        \(preferences.isEmpty ? "No preferences set." : preferences)

        ## Session Feedback
        \(feedback.isEmpty ? "No feedback yet." : feedback)

        ## Current Prompt (version \(version))
        \(promptSection)
        """
    }

    static func buildRequestMessages(
        systemPrompt: String,
        history: [(role: String, content: String)]
    ) -> [[String: String]] {
        var messages: [[String: String]] = [
            ["role": "system", "content": systemPrompt]
        ]
        for msg in history {
            messages.append(["role": msg.role, "content": msg.content])
        }
        return messages
    }
}
