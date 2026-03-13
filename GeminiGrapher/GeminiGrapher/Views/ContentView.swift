import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var chatVM: ChatViewModel
    @State private var sessionListVM = SessionListViewModel()
    @State private var settingsVM = SettingsViewModel()
    private let memoryStore: MemoryStore

    init() {
        let store = MemoryStore()
        self.memoryStore = store
        self._chatVM = State(initialValue: ChatViewModel(memoryStore: store))
    }

    var body: some View {
        NavigationSplitView {
            SessionListView(
                sessionListVM: sessionListVM,
                chatVM: chatVM,
                memoryStore: memoryStore
            )
            .frame(minWidth: 200, idealWidth: 220)
        } content: {
            if chatVM.currentSession != nil {
                ChatView(chatVM: chatVM, model: settingsVM.selectedModel)
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
            PromptPreviewView(chatVM: chatVM)
                .frame(minWidth: 250, idealWidth: 300)
        }
        .frame(minWidth: 900, minHeight: 600)
        .onAppear {
            chatVM.setModelContext(modelContext)
        }
    }
}
