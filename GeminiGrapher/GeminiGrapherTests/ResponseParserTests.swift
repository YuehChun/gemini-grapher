import Testing
@testable import GeminiGrapher

@Suite("ResponseParser")
struct ResponseParserTests {
    @Test("splits chat and prompt on delimiter")
    func splitsChatAndPrompt() {
        let raw = """
        Here is my response about the image.

        ---PROMPT---
        A cyberpunk scene with neon lights...
        """
        let result = ResponseParser.parse(raw)
        #expect(result.chat.contains("Here is my response"))
        #expect(result.prompt == "A cyberpunk scene with neon lights...")
    }

    @Test("returns nil prompt when no delimiter")
    func noDelimiter() {
        let raw = "What style are you looking for?"
        let result = ResponseParser.parse(raw)
        #expect(result.chat == "What style are you looking for?")
        #expect(result.prompt == nil)
    }

    @Test("handles empty prompt after delimiter")
    func emptyPromptAfterDelimiter() {
        let raw = """
        Some chat.

        ---PROMPT---
        """
        let result = ResponseParser.parse(raw)
        #expect(result.chat.contains("Some chat."))
        #expect(result.prompt == nil)
    }

    @Test("trims whitespace from both parts")
    func trimsWhitespace() {
        let raw = """
          Chat content here.  \n\n---PROMPT---\n\n  The prompt content.  \n
        """
        let result = ResponseParser.parse(raw)
        #expect(result.chat == "Chat content here.")
        #expect(result.prompt == "The prompt content.")
    }
}
