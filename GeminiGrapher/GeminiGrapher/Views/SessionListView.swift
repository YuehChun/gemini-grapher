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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Sessions")
                    .font(.title3)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: { showNewSessionAlert = true }) {
                    Image(systemName: "plus.circle.fill")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("New session")
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)

            Divider()

            // Session list
            List(sessionListVM.sessions, selection: Binding(
                get: { chatVM.currentSession?.id },
                set: { id in
                    chatVM.currentSession = sessionListVM.sessions.first { $0.id == id }
                }
            )) { session in
                sessionRow(session)
                    .contextMenu {
                        Button("Rename...") {
                            sessionListVM.editingSessionId = session.id
                        }
                        Divider()
                        Button("Delete", role: .destructive) {
                            sessionListVM.deleteSession(session, context: modelContext, memoryStore: memoryStore)
                            if chatVM.currentSession?.id == session.id {
                                chatVM.currentSession = nil
                            }
                        }
                    }
            }
            .listStyle(.sidebar)

            Divider()

            // Memory section
            memorySection
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
        }
        .onAppear { sessionListVM.loadSessions(context: modelContext) }
        .sheet(isPresented: $showNewSessionAlert) {
            newSessionSheet
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

    // MARK: - Session row

    private func sessionRow(_ session: Session) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(session.name)
                .fontWeight(.medium)
                .lineLimit(1)
            HStack(spacing: 4) {
                Image(systemName: "arrow.triangle.branch")
                    .font(.caption2)
                Text("\(session.latestVersion)")
                Text("·")
                Text(session.updatedAt, style: .relative)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    // MARK: - Memory section

    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("MEMORY")
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundStyle(.tertiary)
                .tracking(1)

            Button {
                memoryEditorType = .preferences
                showMemoryEditor = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "paintpalette")
                        .font(.caption)
                    Text("Style Preferences")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            Button {
                memoryEditorType = .feedback
                showMemoryEditor = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "text.bubble")
                        .font(.caption)
                    Text("Session Feedback")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
    }

    // MARK: - New session sheet

    private var newSessionSheet: some View {
        VStack(spacing: 20) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)

            Text("New Session")
                .font(.headline)

            TextField("Session name", text: $newSessionName)
                .textFieldStyle(.roundedBorder)
                .frame(width: 280)
                .onSubmit {
                    createSessionIfValid()
                }

            HStack(spacing: 12) {
                Button("Cancel") {
                    newSessionName = ""
                    showNewSessionAlert = false
                }
                .keyboardShortcut(.cancelAction)

                Button("Create") {
                    createSessionIfValid()
                }
                .buttonStyle(.borderedProminent)
                .disabled(newSessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(28)
    }

    private func createSessionIfValid() {
        let name = newSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let session = sessionListVM.createSession(name: name, context: modelContext)
        chatVM.currentSession = session
        newSessionName = ""
        showNewSessionAlert = false
    }
}
