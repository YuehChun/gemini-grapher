import Testing
import Foundation
@testable import GeminiGrapher

@Suite("MemoryStore")
struct MemoryStoreTests {
    let tempDir: URL

    init() throws {
        tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("MemoryStoreTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
    }

    @Test("reads preferences from markdown files")
    func readsPreferences() throws {
        let store = MemoryStore(baseDirectory: tempDir)
        let prefsDir = tempDir.appendingPathComponent("preferences")
        try FileManager.default.createDirectory(at: prefsDir, withIntermediateDirectories: true)
        try "# Style\n\n- cinematic lighting\n- no cartoon".write(
            to: prefsDir.appendingPathComponent("style.md"),
            atomically: true, encoding: .utf8
        )
        let content = store.loadPreferences()
        #expect(content.contains("cinematic lighting"))
        #expect(content.contains("no cartoon"))
    }

    @Test("returns empty string when no preferences exist")
    func emptyPreferences() {
        let store = MemoryStore(baseDirectory: tempDir)
        let content = store.loadPreferences()
        #expect(content.isEmpty)
    }

    @Test("reads feedback for a session UUID")
    func readsFeedback() throws {
        let store = MemoryStore(baseDirectory: tempDir)
        let feedbackDir = tempDir.appendingPathComponent("feedback")
        try FileManager.default.createDirectory(at: feedbackDir, withIntermediateDirectories: true)
        let sessionId = UUID()
        try "# Cyberpunk\n\n- too dark last time".write(
            to: feedbackDir.appendingPathComponent("\(sessionId.uuidString).md"),
            atomically: true, encoding: .utf8
        )
        let content = store.loadFeedback(for: sessionId)
        #expect(content.contains("too dark last time"))
    }

    @Test("saves feedback for a session")
    func savesFeedback() throws {
        let store = MemoryStore(baseDirectory: tempDir)
        let sessionId = UUID()
        try store.saveFeedback(for: sessionId, sessionName: "Test", content: "- looks great")
        let path = tempDir.appendingPathComponent("feedback").appendingPathComponent("\(sessionId.uuidString).md")
        let saved = try String(contentsOf: path, encoding: .utf8)
        #expect(saved.contains("# Test"))
        #expect(saved.contains("- looks great"))
    }

    @Test("saves preferences")
    func savesPreferences() throws {
        let store = MemoryStore(baseDirectory: tempDir)
        try store.savePreferences(filename: "style.md", content: "# Style\n\n- vibrant colors")
        let path = tempDir.appendingPathComponent("preferences").appendingPathComponent("style.md")
        let saved = try String(contentsOf: path, encoding: .utf8)
        #expect(saved.contains("vibrant colors"))
    }
}
