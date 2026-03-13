import SwiftUI

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
