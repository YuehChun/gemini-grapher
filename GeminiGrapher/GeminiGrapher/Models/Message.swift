import Foundation
import SwiftData

enum MessageRole: String, Codable {
    case user
    case assistant
    case system
}

@Model
class Message {
    var id: UUID
    var role: MessageRole
    var content: String
    var promptSnapshot: String?
    var version: Int?
    var createdAt: Date
    var session: Session?

    init(
        role: MessageRole,
        content: String,
        promptSnapshot: String? = nil,
        version: Int? = nil
    ) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.promptSnapshot = promptSnapshot
        self.version = version
        self.createdAt = Date()
    }
}
