import SwiftUI
import MarkdownUI

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        HStack {
            if message.role == .user { Spacer(minLength: 60) }
            if message.role == .system {
                Text(message.content)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .italic()
                    .frame(maxWidth: .infinity)
            } else {
                VStack(alignment: message.role == .user ? .trailing : .leading) {
                    let displayContent = extractChatContent(message.content)
                    Markdown(displayContent)
                        .padding(10)
                        .background(
                            message.role == .user
                                ? Color.accentColor.opacity(0.2)
                                : Color(.controlBackgroundColor)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    if let version = message.version {
                        Text("v\(version)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            if message.role == .assistant { Spacer(minLength: 60) }
        }
    }

    private func extractChatContent(_ content: String) -> String {
        ResponseParser.parse(content).chat
    }
}
