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
            .frame(minWidth: 200, idealWidth: 240)
        } content: {
            if chatVM.currentSession != nil {
                ChatView(chatVM: chatVM, model: settingsVM.selectedModel)
                    .frame(minWidth: 400)
            } else {
                emptyState
            }
        } detail: {
            PromptPreviewView(chatVM: chatVM)
                .frame(minWidth: 280, idealWidth: 340)
        }
        .frame(minWidth: 960, minHeight: 640)
        .onAppear {
            chatVM.setModelContext(modelContext)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bubble.left.and.text.bubble.right")
                .font(.system(size: 48))
                .foregroundStyle(.quaternary)
            Text("Select or create a session to begin")
                .foregroundStyle(.tertiary)
                .font(.title3)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
