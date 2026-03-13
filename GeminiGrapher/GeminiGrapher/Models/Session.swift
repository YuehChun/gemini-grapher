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
