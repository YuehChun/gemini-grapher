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
        2. IMPORTANT: You must always BUILD UPON the current prompt below. \
        When the user gives feedback, apply their requested changes to the existing prompt \
        while preserving everything else. Never start from scratch unless explicitly asked. \
        Think of each iteration as a minor revision — add, remove, or tweak specific elements \
        based on user feedback while keeping the rest intact.
        3. Synthesize all fragments into a single, complete, natural-language prompt \
        optimized for Gemini image generation.
        4. When you produce or update a prompt, format your response as:
           - Your conversational reply first (keep it brief)
           - Then the delimiter ---PROMPT--- on its own line
           - Then the complete prompt (not a diff — always the full text)
        5. If you only need to ask a question or discuss (no prompt update), omit the delimiter entirely.
        6. Always output the prompt in English, regardless of the user's language.

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
