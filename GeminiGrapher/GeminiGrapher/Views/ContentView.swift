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
