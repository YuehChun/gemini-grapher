import Testing
@testable import GeminiGrapher

@Suite("SSEParser")
struct SSEParserTests {
    @Test("extracts content from data line")
    func extractsContent() {
        let line = #"data: {"choices":[{"delta":{"content":"Hello"}}]}"#
        let result = SSEParser.parseContentDelta(line)
        #expect(result == "Hello")
    }

    @Test("returns nil for [DONE] signal")
    func handlesDone() {
        let result = SSEParser.parseContentDelta("data: [DONE]")
        #expect(result == nil)
    }

    @Test("returns nil for empty or comment lines")
    func handlesEmpty() {
        #expect(SSEParser.parseContentDelta("") == nil)
        #expect(SSEParser.parseContentDelta(": comment") == nil)
        #expect(SSEParser.parseContentDelta("event: ping") == nil)
    }

    @Test("returns nil when delta has no content key")
    func noContentKey() {
        let line = #"data: {"choices":[{"delta":{"role":"assistant"}}]}"#
        let result = SSEParser.parseContentDelta(line)
        #expect(result == nil)
    }
}
