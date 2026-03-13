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
        .sheet(isPresented: $showNewSessionAlert) {
            VStack(spacing: 16) {
                Text("New Session").font(.headline)
                TextField("Session name", text: $newSessionName)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 250)
                    .onSubmit {
                        createSessionIfValid()
                    }
                HStack(spacing: 12) {
                    Button("Cancel") {
                        newSessionName = ""
                        showNewSessionAlert = false
                    }
                    Button("Create") {
                        createSessionIfValid()
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(newSessionName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding(24)
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

    private func createSessionIfValid() {
        let name = newSessionName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else { return }
        let session = sessionListVM.createSession(name: name, context: modelContext)
        chatVM.currentSession = session
        newSessionName = ""
        showNewSessionAlert = false
    }
}
