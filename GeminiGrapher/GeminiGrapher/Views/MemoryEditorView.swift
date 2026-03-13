import SwiftUI

enum MemoryEditorType {
    case preferences, feedback
}

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
