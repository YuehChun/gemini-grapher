import Foundation
import SwiftData
import SwiftUI

@Observable
class SessionListViewModel {
    var sessions: [Session] = []
    var editingSessionId: UUID?

    func loadSessions(context: ModelContext) {
        let descriptor = FetchDescriptor<Session>(sortBy: [SortDescriptor(\.updatedAt, order: .reverse)])
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
