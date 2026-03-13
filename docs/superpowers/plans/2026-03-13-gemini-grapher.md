# Gemini Grapher Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a macOS Swift app that iteratively refines Gemini image generation prompts through conversation with Claude via vibeproxy.

**Architecture:** Pure SwiftUI three-column app (NavigationSplitView) backed by SwiftData for sessions/messages and Markdown files for memory. LLMClient calls vibeproxy's OpenAI-compatible API with SSE streaming. PromptEngine assembles system prompts injecting memory and current prompt version. Response parsing splits chat from prompt via `---PROMPT---` delimiter.

**Tech Stack:** Swift, SwiftUI, SwiftData, URLSession (async/await + SSE), swift-markdown-ui

**Spec:** `docs/superpowers/specs/2026-03-13-gemini-grapher-design.md`

---

## File Structure

```
GeminiGrapher/
├── GeminiGrapher.xcodeproj
├── GeminiGrapher/
│   ├── GeminiGrapherApp.swift              # App entry point, SwiftData container setup
│   ├── Models/
│   │   ├── Session.swift                    # SwiftData Session model
│   │   ├── Message.swift                    # SwiftData Message model + MessageRole enum
│   ├── Services/
│   │   ├── LLMClient.swift                  # HTTP client for vibeproxy, SSE streaming
│   │   ├── ResponseParser.swift             # Parses ---PROMPT--- delimiter from responses
│   │   ├── PromptEngine.swift               # Builds system prompt with memory + context
│   │   ├── MemoryStore.swift                # Reads/writes Markdown memory files, import/export
│   ├── ViewModels/
│   │   ├── ChatViewModel.swift              # Drives chat interaction, orchestrates LLM calls
│   │   ├── SessionListViewModel.swift       # Session CRUD operations
│   │   ├── SettingsViewModel.swift          # Settings state + model fetching
│   ├── Views/
│   │   ├── ContentView.swift                # NavigationSplitView (3-column root)
│   │   ├── SessionListView.swift            # Left column: session list + memory access
│   │   ├── ChatView.swift                   # Center column: messages + input
│   │   ├── MessageBubbleView.swift          # Single chat bubble
│   │   ├── PromptPreviewView.swift          # Right column: prompt + versions + copy
│   │   ├── MemoryEditorView.swift           # Memory viewing/editing sheet
│   │   ├── SettingsView.swift               # Preferences window
│   ├── Utilities/
│   │   ├── SSEParser.swift                  # Server-Sent Events line parser
│   │   ├── MemoryImportExport.swift         # Zip/unzip memory folder
│   ├── Resources/
│   │   ├── Assets.xcassets                  # App icon, colors
├── GeminiGrapherTests/
│   ├── ResponseParserTests.swift            # Delimiter parsing tests
│   ├── PromptEngineTests.swift              # System prompt assembly tests
│   ├── MemoryStoreTests.swift               # Memory read/write tests
│   ├── SSEParserTests.swift                 # SSE line parsing tests
│   ├── LLMClientTests.swift                 # Request formation tests
```

---

## Chunk 1: Project Scaffold + Data Models

### Task 1: Create Xcode Project

**Files:**
- Create: `GeminiGrapher.xcodeproj` (via Xcode CLI)
- Create: `GeminiGrapher/GeminiGrapherApp.swift`

- [ ] **Step 1: Generate Swift package / Xcode project**

```bash
cd /Users/birdtasi/Documents/Projects/gemini-grapher-master
mkdir -p GeminiGrapher
```

Create the Xcode project using `swift package init` won't work for a macOS app — create it manually. Create the directory structure:

```bash
mkdir -p GeminiGrapher/GeminiGrapher/{Models,Services,ViewModels,Views,Utilities,Resources}
mkdir -p GeminiGrapher/GeminiGrapherTests
```

- [ ] **Step 2: Create app entry point (placeholder — will be updated in Task 2 after models exist)**

Create `GeminiGrapher/GeminiGrapher/GeminiGrapherApp.swift`:

```swift
import SwiftUI

@main
struct GeminiGrapherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }

        Settings {
            SettingsView()
        }
    }
}
```

- [ ] **Step 3: Create placeholder ContentView**

Create `GeminiGrapher/GeminiGrapher/Views/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            Text("Sessions")
        } content: {
            Text("Chat")
        } detail: {
            Text("Prompt Preview")
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
```

- [ ] **Step 4: Create placeholder SettingsView**

Create `GeminiGrapher/GeminiGrapher/Views/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    var body: some View {
        Text("Settings")
            .frame(width: 400, height: 300)
    }
}
```

- [ ] **Step 5: Create Package.swift for SPM-based development**

Create `GeminiGrapher/Package.swift`:

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "GeminiGrapher",
    platforms: [.macOS(.v14)],
    dependencies: [
        .package(url: "https://github.com/gonzalezreal/swift-markdown-ui", from: "2.0.0"),
    ],
    targets: [
        .executableTarget(
            name: "GeminiGrapher",
            dependencies: [
                .product(name: "MarkdownUI", package: "swift-markdown-ui"),
            ],
            path: "GeminiGrapher"
        ),
        .testTarget(
            name: "GeminiGrapherTests",
            dependencies: ["GeminiGrapher"],
            path: "GeminiGrapherTests"
        ),
    ]
)
```

- [ ] **Step 6: Verify project builds**

```bash
cd GeminiGrapher
swift build
```

Expected: Build succeeds (possibly with warnings about unused placeholders).

- [ ] **Step 7: Commit**

```bash
git add GeminiGrapher/
git commit -m "feat: scaffold Xcode project with SwiftUI + SwiftData"
```

---

### Task 2: SwiftData Models

**Files:**
- Create: `GeminiGrapher/GeminiGrapher/Models/Session.swift`
- Create: `GeminiGrapher/GeminiGrapher/Models/Message.swift`

- [ ] **Step 1: Create MessageRole enum and Message model**

Create `GeminiGrapher/GeminiGrapher/Models/Message.swift`:

```swift
import Foundation
import SwiftData

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

@Model
class Message {
    var id: UUID
    var role: MessageRole
    var content: String
    var promptSnapshot: String?
    var version: Int?
    var createdAt: Date
    var session: Session?

    init(
        role: MessageRole,
        content: String,
        promptSnapshot: String? = nil,
        version: Int? = nil
    ) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.promptSnapshot = promptSnapshot
        self.version = version
        self.createdAt = Date()
    }
}
```

- [ ] **Step 2: Create Session model**

Create `GeminiGrapher/GeminiGrapher/Models/Session.swift`:

```swift
import Foundation
import SwiftData

@Model
class Session {
    var id: UUID
    var name: String
    var createdAt: Date
    var updatedAt: Date
    @Relationship(deleteRule: .cascade, inverse: \Message.session)
    var messages: [Message]

    init(name: String) {
        self.id = UUID()
        self.name = name
        self.createdAt = Date()
        self.updatedAt = Date()
        self.messages = []
    }

    var latestVersion: Int {
        messages.compactMap(\.version).max() ?? 0
    }

    var latestPrompt: String? {
        messages
            .filter { $0.promptSnapshot != nil }
            .sorted { $0.createdAt < $1.createdAt }
            .last?.promptSnapshot
    }

    func promptForVersion(_ version: Int) -> String? {
        messages.first { $0.version == version }?.promptSnapshot
    }
}
```

- [ ] **Step 3: Update GeminiGrapherApp.swift to add SwiftData container**

Update `GeminiGrapher/GeminiGrapher/GeminiGrapherApp.swift`:

```swift
import SwiftUI
import SwiftData

@main
struct GeminiGrapherApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: [Session.self, Message.self])

        Settings {
            SettingsView()
        }
    }
}
```

- [ ] **Step 4: Verify build**

```bash
cd GeminiGrapher && swift build
```

Expected: Build succeeds.

- [ ] **Step 5: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/Models/ GeminiGrapher/GeminiGrapher/GeminiGrapherApp.swift
git commit -m "feat: add SwiftData Session and Message models"
```

---

## Chunk 2: Services — ResponseParser + SSEParser

### Task 3: ResponseParser (with TDD)

**Files:**
- Create: `GeminiGrapher/GeminiGrapher/Services/ResponseParser.swift`
- Create: `GeminiGrapher/GeminiGrapherTests/ResponseParserTests.swift`

- [ ] **Step 1: Write failing tests**

Create `GeminiGrapher/GeminiGrapherTests/ResponseParserTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd GeminiGrapher && swift test --filter ResponseParser
```

Expected: Compilation error — `ResponseParser` not defined.

- [ ] **Step 3: Implement ResponseParser**

Create `GeminiGrapher/GeminiGrapher/Services/ResponseParser.swift`:

```swift
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd GeminiGrapher && swift test --filter ResponseParser
```

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/Services/ResponseParser.swift GeminiGrapher/GeminiGrapherTests/ResponseParserTests.swift
git commit -m "feat: add ResponseParser with ---PROMPT--- delimiter parsing"
```

---

### Task 4: SSEParser (with TDD)

**Files:**
- Create: `GeminiGrapher/GeminiGrapher/Utilities/SSEParser.swift`
- Create: `GeminiGrapher/GeminiGrapherTests/SSEParserTests.swift`

- [ ] **Step 1: Write failing tests**

Create `GeminiGrapher/GeminiGrapherTests/SSEParserTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd GeminiGrapher && swift test --filter SSEParser
```

Expected: Compilation error — `SSEParser` not defined.

- [ ] **Step 3: Implement SSEParser**

Create `GeminiGrapher/GeminiGrapher/Utilities/SSEParser.swift`:

```swift
import Foundation

enum SSEParser {
    /// Extracts the content delta string from an SSE data line.
    /// Returns nil for non-content lines ([DONE], comments, empty, role-only deltas).
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd GeminiGrapher && swift test --filter SSEParser
```

Expected: All 4 tests pass.

- [ ] **Step 5: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/Utilities/SSEParser.swift GeminiGrapher/GeminiGrapherTests/SSEParserTests.swift
git commit -m "feat: add SSEParser for OpenAI-compatible streaming responses"
```

---

## Chunk 3: Services — PromptEngine + MemoryStore

### Task 5: MemoryStore (with TDD)

**Files:**
- Create: `GeminiGrapher/GeminiGrapher/Services/MemoryStore.swift`
- Create: `GeminiGrapher/GeminiGrapherTests/MemoryStoreTests.swift`

- [ ] **Step 1: Write failing tests**

Create `GeminiGrapher/GeminiGrapherTests/MemoryStoreTests.swift`:

```swift
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

        let path = tempDir
            .appendingPathComponent("feedback")
            .appendingPathComponent("\(sessionId.uuidString).md")
        let saved = try String(contentsOf: path, encoding: .utf8)
        #expect(saved.contains("# Test"))
        #expect(saved.contains("- looks great"))
    }

    @Test("saves preferences")
    func savesPreferences() throws {
        let store = MemoryStore(baseDirectory: tempDir)
        try store.savePreferences(filename: "style.md", content: "# Style\n\n- vibrant colors")

        let path = tempDir
            .appendingPathComponent("preferences")
            .appendingPathComponent("style.md")
        let saved = try String(contentsOf: path, encoding: .utf8)
        #expect(saved.contains("vibrant colors"))
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd GeminiGrapher && swift test --filter MemoryStore
```

Expected: Compilation error — `MemoryStore` not defined.

- [ ] **Step 3: Implement MemoryStore**

Create `GeminiGrapher/GeminiGrapher/Services/MemoryStore.swift`:

```swift
import Foundation

class MemoryStore {
    let baseDirectory: URL

    init(baseDirectory: URL? = nil) {
        if let dir = baseDirectory {
            self.baseDirectory = dir
        } else {
            self.baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("GeminiGrapher")
                .appendingPathComponent("memory")
        }
    }

    private var preferencesDirectory: URL {
        baseDirectory.appendingPathComponent("preferences")
    }

    private var feedbackDirectory: URL {
        baseDirectory.appendingPathComponent("feedback")
    }

    // MARK: - Preferences

    func loadPreferences() -> String {
        guard FileManager.default.fileExists(atPath: preferencesDirectory.path) else { return "" }

        let files = (try? FileManager.default.contentsOfDirectory(
            at: preferencesDirectory, includingPropertiesForKeys: nil
        )) ?? []

        return files
            .filter { $0.pathExtension == "md" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { try? String(contentsOf: $0, encoding: .utf8) }
            .joined(separator: "\n\n")
    }

    func savePreferences(filename: String, content: String) throws {
        try FileManager.default.createDirectory(at: preferencesDirectory, withIntermediateDirectories: true)
        let path = preferencesDirectory.appendingPathComponent(filename)
        try content.write(to: path, atomically: true, encoding: .utf8)
    }

    func listPreferenceFiles() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: preferencesDirectory, includingPropertiesForKeys: nil
        ))?.filter { $0.pathExtension == "md" } ?? []
    }

    // MARK: - Feedback

    func loadFeedback(for sessionId: UUID) -> String {
        let path = feedbackDirectory.appendingPathComponent("\(sessionId.uuidString).md")
        return (try? String(contentsOf: path, encoding: .utf8)) ?? ""
    }

    func saveFeedback(for sessionId: UUID, sessionName: String, content: String) throws {
        try FileManager.default.createDirectory(at: feedbackDirectory, withIntermediateDirectories: true)
        let path = feedbackDirectory.appendingPathComponent("\(sessionId.uuidString).md")
        let fullContent = "# \(sessionName)\n\n\(content)"
        try fullContent.write(to: path, atomically: true, encoding: .utf8)
    }

    func deleteFeedback(for sessionId: UUID) {
        let path = feedbackDirectory.appendingPathComponent("\(sessionId.uuidString).md")
        try? FileManager.default.removeItem(at: path)
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd GeminiGrapher && swift test --filter MemoryStore
```

Expected: All 5 tests pass.

- [ ] **Step 5: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/Services/MemoryStore.swift GeminiGrapher/GeminiGrapherTests/MemoryStoreTests.swift
git commit -m "feat: add MemoryStore for Markdown-based memory persistence"
```

---

### Task 6: PromptEngine (with TDD)

**Files:**
- Create: `GeminiGrapher/GeminiGrapher/Services/PromptEngine.swift`
- Create: `GeminiGrapher/GeminiGrapherTests/PromptEngineTests.swift`

- [ ] **Step 1: Write failing tests**

Create `GeminiGrapher/GeminiGrapherTests/PromptEngineTests.swift`:

```swift
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
        let prompt = PromptEngine.buildSystemPrompt(
            preferences: "",
            feedback: "",
            currentPrompt: nil,
            version: 0
        )

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

        #expect(result.count == 3)  // system + user + assistant
        #expect(result[0]["role"] == "system")
        #expect(result[1]["role"] == "user")
        #expect(result[2]["role"] == "assistant")
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd GeminiGrapher && swift test --filter PromptEngine
```

Expected: Compilation error — `PromptEngine` not defined.

- [ ] **Step 3: Implement PromptEngine**

Create `GeminiGrapher/GeminiGrapher/Services/PromptEngine.swift`:

```swift
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd GeminiGrapher && swift test --filter PromptEngine
```

Expected: All 3 tests pass.

- [ ] **Step 5: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/Services/PromptEngine.swift GeminiGrapher/GeminiGrapherTests/PromptEngineTests.swift
git commit -m "feat: add PromptEngine for system prompt assembly"
```

---

## Chunk 4: LLMClient + ChatViewModel

### Task 7: LLMClient

**Files:**
- Create: `GeminiGrapher/GeminiGrapher/Services/LLMClient.swift`
- Create: `GeminiGrapher/GeminiGrapherTests/LLMClientTests.swift`

- [ ] **Step 1: Write tests for request formation**

Create `GeminiGrapher/GeminiGrapherTests/LLMClientTests.swift`:

```swift
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
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
cd GeminiGrapher && swift test --filter LLMClient
```

Expected: Compilation error.

- [ ] **Step 3: Implement LLMClient**

Create `GeminiGrapher/GeminiGrapher/Services/LLMClient.swift`:

```swift
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

    /// Streams a chat completion, yielding content deltas as they arrive.
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

    /// Fetches available models from vibeproxy.
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
cd GeminiGrapher && swift test --filter LLMClient
```

Expected: All 2 tests pass.

- [ ] **Step 5: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/Services/LLMClient.swift GeminiGrapher/GeminiGrapherTests/LLMClientTests.swift
git commit -m "feat: add LLMClient with SSE streaming for vibeproxy"
```

---

### Task 8: ChatViewModel

**Files:**
- Create: `GeminiGrapher/GeminiGrapher/ViewModels/ChatViewModel.swift`

- [ ] **Step 1: Implement ChatViewModel**

Create `GeminiGrapher/GeminiGrapher/ViewModels/ChatViewModel.swift`:

```swift
import Foundation
import SwiftData
import SwiftUI

@Observable
class ChatViewModel {
    var currentSession: Session?
    var inputText: String = ""
    var isStreaming: Bool = false
    var streamingChat: String = ""
    var streamingPrompt: String = ""
    var error: String?
    var selectedVersion: Int?

    private let llmClient: LLMClient
    let memoryStore: MemoryStore
    private var modelContext: ModelContext?

    init(llmClient: LLMClient = LLMClient(), memoryStore: MemoryStore) {
        self.llmClient = llmClient
        self.memoryStore = memoryStore
    }

    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }

    var displayedPrompt: String? {
        if let version = selectedVersion {
            return currentSession?.promptForVersion(version)
        }
        if !streamingPrompt.isEmpty { return streamingPrompt }
        return currentSession?.latestPrompt
    }

    var displayedVersion: Int {
        selectedVersion ?? currentSession?.latestVersion ?? 0
    }

    var promptVersions: [Int] {
        currentSession?.messages
            .compactMap(\.version)
            .sorted() ?? []
    }

    func send(model: String) async {
        guard let session = currentSession,
              !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        else { return }

        let userText = inputText
        inputText = ""
        error = nil
        selectedVersion = nil

        // Add user message
        let userMessage = Message(role: .user, content: userText)
        session.messages.append(userMessage)
        session.updatedAt = Date()

        // Build system prompt
        let preferences = memoryStore.loadPreferences()
        let feedback = memoryStore.loadFeedback(for: session.id)
        let systemPrompt = PromptEngine.buildSystemPrompt(
            preferences: preferences,
            feedback: feedback,
            currentPrompt: session.latestPrompt,
            version: session.latestVersion
        )

        let history = session.messages.map { (role: $0.role.rawValue, content: $0.content) }
        let requestMessages = PromptEngine.buildRequestMessages(
            systemPrompt: systemPrompt,
            history: history
        )

        // Stream response
        isStreaming = true
        streamingChat = ""
        streamingPrompt = ""
        var fullResponse = ""
        var delimiterFound = false

        do {
            for try await delta in llmClient.streamCompletion(messages: requestMessages, model: model) {
                fullResponse += delta

                // Check for delimiter on complete lines
                if !delimiterFound {
                    let lines = fullResponse.components(separatedBy: "\n")
                    if lines.contains(ResponseParser.delimiter) {
                        delimiterFound = true
                        let parsed = ResponseParser.parse(fullResponse)
                        streamingChat = parsed.chat
                        streamingPrompt = parsed.prompt ?? ""
                    } else {
                        streamingChat = fullResponse
                    }
                } else {
                    let parsed = ResponseParser.parse(fullResponse)
                    streamingChat = parsed.chat
                    streamingPrompt = parsed.prompt ?? ""
                }
            }

            // Finalize: parse complete response and save message
            let parsed = ResponseParser.parse(fullResponse)
            let nextVersion: Int? = parsed.prompt != nil ? session.latestVersion + 1 : nil
            let assistantMessage = Message(
                role: .assistant,
                content: fullResponse,
                promptSnapshot: parsed.prompt,
                version: nextVersion
            )
            session.messages.append(assistantMessage)
            session.updatedAt = Date()

            streamingChat = ""
            streamingPrompt = ""
            isStreaming = false

            try? modelContext?.save()
        } catch {
            self.error = error.localizedDescription
            isStreaming = false
            streamingChat = ""
            streamingPrompt = ""
        }
    }

    func resumeFromVersion(_ version: Int) {
        guard let session = currentSession,
              let prompt = session.promptForVersion(version)
        else { return }

        let systemNote = Message(role: .system, content: "Resuming from v\(version)")
        systemNote.promptSnapshot = prompt
        systemNote.version = version
        session.messages.append(systemNote)
        selectedVersion = nil

        try? modelContext?.save()
    }

    func retry(model: String) async {
        guard let session = currentSession else { return }

        // Remove the last assistant message if it was an error
        if let lastMessage = session.messages.last, lastMessage.role == .assistant {
            session.messages.removeAll { $0.id == lastMessage.id }
            modelContext?.delete(lastMessage)
        }

        // Re-send with the last user message
        if let lastUserMessage = session.messages.last(where: { $0.role == .user }) {
            inputText = lastUserMessage.content
            session.messages.removeAll { $0.id == lastUserMessage.id }
            modelContext?.delete(lastUserMessage)
            await send(model: model)
        }
    }

    func copyPromptToClipboard() {
        guard let prompt = displayedPrompt else { return }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(prompt, forType: .string)
    }
}
```

- [ ] **Step 2: Verify build**

```bash
cd GeminiGrapher && swift build
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/ViewModels/ChatViewModel.swift
git commit -m "feat: add ChatViewModel orchestrating LLM calls and streaming"
```

---

## Chunk 5: Views — Three-Column Layout

### Task 9: SessionListViewModel + SessionListView

**Files:**
- Create: `GeminiGrapher/GeminiGrapher/ViewModels/SessionListViewModel.swift`
- Create: `GeminiGrapher/GeminiGrapher/Views/SessionListView.swift`

- [ ] **Step 1: Create SessionListViewModel**

Create `GeminiGrapher/GeminiGrapher/ViewModels/SessionListViewModel.swift`:

```swift
import Foundation
import SwiftData
import SwiftUI

@Observable
class SessionListViewModel {
    var sessions: [Session] = []
    var editingSessionId: UUID?

    func loadSessions(context: ModelContext) {
        let descriptor = FetchDescriptor<Session>(
            sortBy: [SortDescriptor(\.updatedAt, order: .reverse)]
        )
        sessions = (try? context.fetch(descriptor)) ?? []
    }

    func createSession(name: String, context: ModelContext) -> Session {
        let session = Session(name: name)
        context.insert(session)
        try? context.save()
        loadSessions(context: context)
        return session
    }

    func deleteSession(_ session: Session, context: ModelContext, memoryStore: MemoryStore) {
        memoryStore.deleteFeedback(for: session.id)
        context.delete(session)
        try? context.save()
        loadSessions(context: context)
    }

    func renameSession(_ session: Session, to name: String, context: ModelContext) {
        session.name = name
        session.updatedAt = Date()
        try? context.save()
        loadSessions(context: context)
    }
}
```

- [ ] **Step 2: Create SessionListView**

Create `GeminiGrapher/GeminiGrapher/Views/SessionListView.swift`:

```swift
import SwiftUI
import SwiftData

struct SessionListView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var sessionListVM: SessionListViewModel
    @Bindable var chatVM: ChatViewModel
    let memoryStore: MemoryStore
    @State private var showNewSessionAlert = false
    @State private var newSessionName = ""
    @State private var showMemoryEditor = false
    @State private var memoryEditorType: MemoryEditorType = .preferences

    enum MemoryEditorType {
        case preferences, feedback
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Sessions").font(.headline)
                Spacer()
                Button(action: { showNewSessionAlert = true }) {
                    Image(systemName: "plus")
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)

            Divider()

            // Session list
            List(sessionListVM.sessions, selection: Binding(
                get: { chatVM.currentSession?.id },
                set: { id in
                    chatVM.currentSession = sessionListVM.sessions.first { $0.id == id }
                }
            )) { session in
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.name).fontWeight(.medium)
                    HStack {
                        Text("\(session.latestVersion) versions")
                        Text("·")
                        Text(session.updatedAt, style: .relative)
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
                .contextMenu {
                    Button("Rename...") {
                        sessionListVM.editingSessionId = session.id
                    }
                    Button("Delete", role: .destructive) {
                        sessionListVM.deleteSession(session, context: modelContext, memoryStore: memoryStore)
                        if chatVM.currentSession?.id == session.id {
                            chatVM.currentSession = nil
                        }
                    }
                }
            }

            Divider()

            // Memory section
            VStack(alignment: .leading, spacing: 6) {
                Text("Memory")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)

                Button("Style Preferences") {
                    memoryEditorType = .preferences
                    showMemoryEditor = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.purple)
                .font(.caption)

                Button("Session Feedback") {
                    memoryEditorType = .feedback
                    showMemoryEditor = true
                }
                .buttonStyle(.plain)
                .foregroundStyle(.purple)
                .font(.caption)
            }
            .padding(12)
        }
        .onAppear { sessionListVM.loadSessions(context: modelContext) }
        .alert("New Session", isPresented: $showNewSessionAlert) {
            TextField("Session name", text: $newSessionName)
            Button("Create") {
                if !newSessionName.isEmpty {
                    let session = sessionListVM.createSession(name: newSessionName, context: modelContext)
                    chatVM.currentSession = session
                    newSessionName = ""
                }
            }
            Button("Cancel", role: .cancel) { newSessionName = "" }
        }
        .sheet(isPresented: $showMemoryEditor) {
            MemoryEditorView(
                memoryStore: memoryStore,
                type: memoryEditorType,
                sessionId: chatVM.currentSession?.id,
                sessionName: chatVM.currentSession?.name
            )
        }
    }
}
```

- [ ] **Step 3: Create MemoryEditorView stub (to unblock build)**

Create `GeminiGrapher/GeminiGrapher/Views/MemoryEditorView.swift`:

```swift
import SwiftUI

// Stub — full implementation in Task 12
enum MemoryEditorType {
    case preferences, feedback
}

struct MemoryEditorView: View {
    let memoryStore: MemoryStore
    let type: MemoryEditorType
    let sessionId: UUID?
    let sessionName: String?

    var body: some View {
        Text("Memory Editor — placeholder")
            .frame(width: 400, height: 300)
    }
}
```

- [ ] **Step 4: Update SessionListView to use top-level MemoryEditorType**

In `SessionListView`, remove the nested `MemoryEditorType` enum and use the top-level one defined in `MemoryEditorView.swift`.

- [ ] **Step 5: Verify build**

```bash
cd GeminiGrapher && swift build
```

Expected: Build succeeds.

- [ ] **Step 6: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/ViewModels/SessionListViewModel.swift GeminiGrapher/GeminiGrapher/Views/SessionListView.swift GeminiGrapher/GeminiGrapher/Views/MemoryEditorView.swift
git commit -m "feat: add SessionListView with CRUD and memory access"
```

---

### Task 10: MessageBubbleView + ChatView

**Files:**
- Create: `GeminiGrapher/GeminiGrapher/Views/MessageBubbleView.swift`
- Create: `GeminiGrapher/GeminiGrapher/Views/ChatView.swift`

- [ ] **Step 1: Create MessageBubbleView**

Create `GeminiGrapher/GeminiGrapher/Views/MessageBubbleView.swift`:

```swift
import SwiftUI
import MarkdownUI

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }

            if message.role == .system {
                Text(message.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: message.role == .user ? .trailing : .leading) {
                    let displayContent = extractChatContent(message.content)
                    Markdown(displayContent)
                        .padding(10)
                        .background(
                            message.role == .user
                                ? Color.accentColor.opacity(0.2)
                                : Color(.controlBackgroundColor)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    if let version = message.version {
                        Text("v\(version)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }

    private func extractChatContent(_ content: String) -> String {
        ResponseParser.parse(content).chat
    }
}
```

- [ ] **Step 2: Create ChatView**

Create `GeminiGrapher/GeminiGrapher/Views/ChatView.swift`:

```swift
import SwiftUI
import MarkdownUI

struct ChatView: View {
    @Bindable var chatVM: ChatViewModel
    let model: String

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text(chatVM.currentSession?.name ?? "No Session")
                    .font(.headline)
                if chatVM.displayedVersion > 0 {
                    Text("v\(chatVM.displayedVersion)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let session = chatVM.currentSession {
                            ForEach(session.messages.sorted(by: { $0.createdAt < $1.createdAt })) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                        }

                        // Streaming bubble
                        if chatVM.isStreaming && !chatVM.streamingChat.isEmpty {
                            HStack {
                                VStack(alignment: .leading) {
                                    Markdown(chatVM.streamingChat)
                                        .padding(10)
                                        .background(Color(.controlBackgroundColor))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                Spacer(minLength: 60)
                            }
                            .id("streaming")
                        }

                        // Error
                        if let error = chatVM.error {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(error)
                                        .foregroundStyle(.red)
                                        .font(.callout)
                                    Button("Retry") {
                                        Task { await chatVM.retry(model: model) }
                                    }
                                    .buttonStyle(.bordered)
                                }
                                Spacer()
                            }
                            .padding(10)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: chatVM.streamingChat) {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }

            Divider()

            // Input
            HStack(spacing: 8) {
                TextField("Describe what you want to adjust...", text: $chatVM.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .onSubmit {
                        if !NSEvent.modifierFlags.contains(.shift) {
                            Task { await chatVM.send(model: model) }
                        }
                    }

                Button(action: {
                    Task { await chatVM.send(model: model) }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(chatVM.isStreaming || chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
        }
    }
}
```

- [ ] **Step 3: Verify build**

```bash
cd GeminiGrapher && swift build
```

- [ ] **Step 4: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/Views/MessageBubbleView.swift GeminiGrapher/GeminiGrapher/Views/ChatView.swift
git commit -m "feat: add ChatView with message bubbles and streaming display"
```

---

### Task 11: PromptPreviewView

**Files:**
- Create: `GeminiGrapher/GeminiGrapher/Views/PromptPreviewView.swift`

- [ ] **Step 1: Implement PromptPreviewView**

Create `GeminiGrapher/GeminiGrapher/Views/PromptPreviewView.swift`:

```swift
import SwiftUI

struct PromptPreviewView: View {
    @Bindable var chatVM: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Prompt").font(.headline)
                Spacer()
                if chatVM.displayedVersion > 0 {
                    Text("v\(chatVM.displayedVersion)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Button(action: { chatVM.copyPromptToClipboard() }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(chatVM.displayedPrompt == nil)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Prompt content
            ScrollView {
                if let prompt = chatVM.displayedPrompt {
                    Text(prompt)
                        .font(.body)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "text.quote")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Start a conversation to generate a prompt")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(16)
                }
            }

            Divider()

            // Version selector
            if !chatVM.promptVersions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Text("Versions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(chatVM.promptVersions, id: \.self) { version in
                            Button("v\(version)") {
                                if chatVM.selectedVersion == version {
                                    chatVM.selectedVersion = nil  // deselect = go to latest
                                } else {
                                    chatVM.selectedVersion = version
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                chatVM.displayedVersion == version
                                    ? Color.accentColor.opacity(0.2)
                                    : Color(.controlBackgroundColor)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }

                        if chatVM.selectedVersion != nil {
                            Button("Resume from v\(chatVM.selectedVersion!)") {
                                chatVM.resumeFromVersion(chatVM.selectedVersion!)
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(12)
                }
            }
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
cd GeminiGrapher && swift build
```

- [ ] **Step 3: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/Views/PromptPreviewView.swift
git commit -m "feat: add PromptPreviewView with version selector and copy"
```

---

## Chunk 6: MemoryEditorView + SettingsView + Wire Up

### Task 12: MemoryEditorView + MemoryImportExport

**Files:**
- Create: `GeminiGrapher/GeminiGrapher/Views/MemoryEditorView.swift`
- Create: `GeminiGrapher/GeminiGrapher/Utilities/MemoryImportExport.swift`

- [ ] **Step 1: Create MemoryImportExport**

Create `GeminiGrapher/GeminiGrapher/Utilities/MemoryImportExport.swift`:

```swift
import Foundation
import AppKit

enum MemoryImportExport {
    /// Exports memory folder as a zip file. Opens save dialog.
    static func exportMemory(from baseDir: URL) throws {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "memory-export.zip"
        panel.allowedContentTypes = [.zip]

        guard panel.runModal() == .OK, let destination = panel.url else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--sequesterRsrc", baseDir.path, destination.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw MemoryIOError.exportFailed
        }
    }

    /// Imports memory from a zip file or folder. Shows confirmation dialog.
    static func importMemory(to baseDir: URL) throws {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.zip, .folder]
        panel.canChooseDirectories = true
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let source = panel.url else { return }

        // Validate structure
        let sourceDir: URL
        if source.pathExtension == "zip" {
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("memory-import-\(UUID().uuidString)")
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-x", "-k", source.path, tempDir.path]
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw MemoryIOError.importFailed }
            sourceDir = tempDir
        } else {
            sourceDir = source
        }

        // Validate: must contain preferences/ or feedback/
        let hasPrefs = FileManager.default.fileExists(
            atPath: sourceDir.appendingPathComponent("preferences").path
        )
        let hasFeedback = FileManager.default.fileExists(
            atPath: sourceDir.appendingPathComponent("feedback").path
        )
        guard hasPrefs || hasFeedback else {
            throw MemoryIOError.invalidStructure
        }

        // Confirmation
        let alert = NSAlert()
        alert.messageText = "Replace existing memory?"
        alert.informativeText = "This will replace all current memory files. This cannot be undone."
        alert.addButton(withTitle: "Replace")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        // Replace
        if FileManager.default.fileExists(atPath: baseDir.path) {
            try FileManager.default.removeItem(at: baseDir)
        }
        try FileManager.default.copyItem(at: sourceDir, to: baseDir)
    }

    /// Opens memory folder in Finder.
    static func openInFinder(_ baseDir: URL) {
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(baseDir)
    }
}

enum MemoryIOError: LocalizedError {
    case exportFailed
    case importFailed
    case invalidStructure

    var errorDescription: String? {
        switch self {
        case .exportFailed: return "Failed to export memory."
        case .importFailed: return "Failed to import memory archive."
        case .invalidStructure: return "Invalid memory folder. Must contain preferences/ or feedback/ subdirectory."
        }
    }
}
```

- [ ] **Step 2: Replace MemoryEditorView stub with full implementation**

Replace `GeminiGrapher/GeminiGrapher/Views/MemoryEditorView.swift`:

```swift
import SwiftUI

struct MemoryEditorView: View {
    let memoryStore: MemoryStore
    let type: MemoryEditorType
    let sessionId: UUID?
    let sessionName: String?

    @State private var content: String = ""
    @State private var errorMessage: String?
    @Environment(\.dismiss) private var dismiss

    var title: String {
        switch type {
        case .preferences: return "Style Preferences"
        case .feedback: return "Session Feedback"
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(title).font(.headline)
                Spacer()

                if type == .preferences {
                    Button("Open in Finder") {
                        MemoryImportExport.openInFinder(memoryStore.baseDirectory)
                    }
                    .buttonStyle(.bordered)

                    Button("Export") {
                        do {
                            try MemoryImportExport.exportMemory(from: memoryStore.baseDirectory)
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .buttonStyle(.bordered)

                    Button("Import") {
                        do {
                            try MemoryImportExport.importMemory(to: memoryStore.baseDirectory)
                            loadContent()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                    }
                    .buttonStyle(.bordered)
                }

                Button("Done") { dismiss() }
                    .buttonStyle(.borderedProminent)
            }
            .padding()

            Divider()

            TextEditor(text: $content)
                .font(.body.monospaced())
                .padding(8)

            if let error = errorMessage {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
                    .padding(.horizontal)
            }
        }
        .frame(width: 600, height: 400)
        .onAppear { loadContent() }
        .onDisappear { saveContent() }
    }

    private func loadContent() {
        switch type {
        case .preferences:
            content = memoryStore.loadPreferences()
        case .feedback:
            if let sessionId {
                content = memoryStore.loadFeedback(for: sessionId)
            }
        }
    }

    private func saveContent() {
        switch type {
        case .preferences:
            try? memoryStore.savePreferences(filename: "style.md", content: content)
        case .feedback:
            if let sessionId, let sessionName {
                try? memoryStore.saveFeedback(for: sessionId, sessionName: sessionName, content: content)
            }
        }
    }
}
```

- [ ] **Step 3: Verify build**

```bash
cd GeminiGrapher && swift build
```

- [ ] **Step 4: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/Views/MemoryEditorView.swift GeminiGrapher/GeminiGrapher/Utilities/MemoryImportExport.swift
git commit -m "feat: add MemoryEditorView with import/export support"
```

---

### Task 13: SettingsView + SettingsViewModel

**Files:**
- Modify: `GeminiGrapher/GeminiGrapher/Views/SettingsView.swift`
- Create: `GeminiGrapher/GeminiGrapher/ViewModels/SettingsViewModel.swift`

- [ ] **Step 1: Create SettingsViewModel**

Create `GeminiGrapher/GeminiGrapher/ViewModels/SettingsViewModel.swift`:

```swift
import Foundation

@Observable
class SettingsViewModel {
    var baseURL: String {
        didSet { UserDefaults.standard.set(baseURL, forKey: "vibeproxyURL") }
    }
    var selectedModel: String {
        didSet { UserDefaults.standard.set(selectedModel, forKey: "selectedModel") }
    }
    var availableModels: [String] = []
    var isLoadingModels = false

    init() {
        self.baseURL = UserDefaults.standard.string(forKey: "vibeproxyURL") ?? "http://localhost:8317"
        self.selectedModel = UserDefaults.standard.string(forKey: "selectedModel") ?? "claude-sonnet-4-6"
    }

    func fetchModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }

        let client = LLMClient(baseURL: baseURL)
        do {
            availableModels = try await client.fetchModels()
            if !availableModels.contains(selectedModel), let first = availableModels.first {
                selectedModel = first
            }
        } catch {
            availableModels = []
        }
    }
}
```

- [ ] **Step 2: Update SettingsView**

Replace `GeminiGrapher/GeminiGrapher/Views/SettingsView.swift`:

```swift
import SwiftUI

struct SettingsView: View {
    @State private var vm = SettingsViewModel()

    var body: some View {
        Form {
            Section("VibeProxy") {
                TextField("Base URL", text: $vm.baseURL)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Model") {
                Picker("Model", selection: $vm.selectedModel) {
                    if vm.availableModels.isEmpty {
                        Text(vm.selectedModel).tag(vm.selectedModel)
                    }
                    ForEach(vm.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }

                Button(vm.isLoadingModels ? "Loading..." : "Refresh Models") {
                    Task { await vm.fetchModels() }
                }
                .disabled(vm.isLoadingModels)
            }

            Section("Memory") {
                HStack {
                    Text("Folder:")
                    Text(MemoryStore().baseDirectory.path)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Button("Open in Finder") {
                    MemoryImportExport.openInFinder(MemoryStore().baseDirectory)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 320)
        .task { await vm.fetchModels() }
    }
}
```

- [ ] **Step 3: Verify build**

```bash
cd GeminiGrapher && swift build
```

- [ ] **Step 4: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/ViewModels/SettingsViewModel.swift GeminiGrapher/GeminiGrapher/Views/SettingsView.swift
git commit -m "feat: add Settings with vibeproxy URL and model selection"
```

---

### Task 14: Wire Up ContentView

**Files:**
- Modify: `GeminiGrapher/GeminiGrapher/Views/ContentView.swift`

- [ ] **Step 1: Update ContentView to wire all views**

Replace `GeminiGrapher/GeminiGrapher/Views/ContentView.swift`:

```swift
import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    private let memoryStore = MemoryStore()
    @State private var chatVM: ChatViewModel?
    @State private var sessionListVM = SessionListViewModel()
    @State private var settingsVM = SettingsViewModel()

    private var resolvedChatVM: ChatViewModel {
        if chatVM == nil { chatVM = ChatViewModel(memoryStore: memoryStore) }
        return chatVM!
    }

    var body: some View {
        NavigationSplitView {
            SessionListView(
                sessionListVM: sessionListVM,
                chatVM: resolvedChatVM,
                memoryStore: memoryStore
            )
            .frame(minWidth: 200, idealWidth: 220)
        } content: {
            if resolvedChatVM.currentSession != nil {
                ChatView(chatVM: resolvedChatVM, model: settingsVM.selectedModel)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "bubble.left.and.text.bubble.right")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("Select or create a session to begin")
                        .foregroundStyle(.secondary)
                }
            }
        } detail: {
            PromptPreviewView(chatVM: resolvedChatVM)
                .frame(minWidth: 250, idealWidth: 300)
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            resolvedChatVM.setModelContext(modelContext)
        }
    }
}
```

- [ ] **Step 2: Verify build**

```bash
cd GeminiGrapher && swift build
```

- [ ] **Step 3: Run the app to smoke test**

```bash
cd GeminiGrapher && swift run
```

Expected: App opens with three-column layout. Left shows empty session list with "+" button. Center shows "Select or create a session" placeholder. Right shows empty prompt preview.

- [ ] **Step 4: Commit**

```bash
git add GeminiGrapher/GeminiGrapher/Views/ContentView.swift
git commit -m "feat: wire up three-column layout in ContentView"
```

---

## Chunk 7: Integration Testing + Polish

### Task 15: Add .gitignore

**Files:**
- Create: `GeminiGrapher/.gitignore`

- [ ] **Step 1: Create .gitignore**

Create `GeminiGrapher/.gitignore`:

```
.build/
.DS_Store
*.xcodeproj/xcuserdata/
DerivedData/
.swiftpm/
```

- [ ] **Step 2: Commit**

```bash
git add GeminiGrapher/.gitignore
git commit -m "chore: add .gitignore for Swift project"
```

---

### Task 16: Run All Tests

- [ ] **Step 1: Run full test suite**

```bash
cd GeminiGrapher && swift test
```

Expected: All tests pass (ResponseParser: 4, SSEParser: 4, MemoryStore: 5, PromptEngine: 3, LLMClient: 2 = 18 tests total).

- [ ] **Step 2: If any tests fail, fix the specific failures and re-run**

```bash
cd GeminiGrapher && swift test
```

Expected: All 18 tests pass.

- [ ] **Step 3: Commit fixes if any were needed**

```bash
git add GeminiGrapher/
git commit -m "fix: resolve test failures"
```

---

### Task 17: End-to-End Smoke Test

**Prerequisite:** vibeproxy must be running on `localhost:8317`.

- [ ] **Step 1: Verify vibeproxy connectivity**

```bash
curl -s http://localhost:8317/v1/models | head -c 200
```

Expected: JSON with model list. If this fails, start vibeproxy before proceeding.

- [ ] **Step 2: Launch app and test full flow**

```bash
cd GeminiGrapher && swift run
```

Manual test checklist (human-driven):
1. Click "+" to create a session named "Test"
2. Type "A cat sitting on a moon" and press Enter
3. Verify: chat shows Claude's response, right panel shows generated prompt
4. Type "Make it watercolor style" and press Enter
5. Verify: right panel updates with new prompt (v2)
6. Click "Copy" button — paste in a text editor to verify
7. Click v1 in version selector — verify old prompt shows
8. Open Settings — verify model list loads
9. Open Memory > Style Preferences — type "- always add warm lighting" and close
10. Send another message — verify prompt incorporates the preference

- [ ] **Step 3: Commit any fixes from smoke test**

```bash
git add GeminiGrapher/
git commit -m "fix: address smoke test issues"
```

(Only if changes were made.)
