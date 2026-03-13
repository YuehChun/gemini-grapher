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

        let userMessage = Message(role: .user, content: userText)
        session.messages.append(userMessage)
        session.updatedAt = Date()

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

        isStreaming = true
        streamingChat = ""
        streamingPrompt = ""
        var fullResponse = ""
        var delimiterFound = false

        do {
            for try await delta in llmClient.streamCompletion(messages: requestMessages, model: model) {
                fullResponse += delta
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
        if let lastMessage = session.messages.last, lastMessage.role == .assistant {
            session.messages.removeAll { $0.id == lastMessage.id }
            modelContext?.delete(lastMessage)
        }
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
