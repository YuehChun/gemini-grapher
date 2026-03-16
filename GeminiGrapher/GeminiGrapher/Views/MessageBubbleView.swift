import SwiftUI
import MarkdownUI

struct MessageBubbleView: View {
    let message: Message

    var body: some View {
        switch message.role {
        case .system:
            systemMessage
        case .user:
            userMessage
        case .assistant:
            assistantMessage
        }
    }

    // MARK: - System message

    private var systemMessage: some View {
        HStack(spacing: 6) {
            Rectangle()
                .fill(Color(.separatorColor))
                .frame(height: 0.5)
            Text(message.content)
                .font(.caption)
                .foregroundStyle(.tertiary)
                .lineLimit(1)
            Rectangle()
                .fill(Color(.separatorColor))
                .frame(height: 0.5)
        }
        .padding(.vertical, 4)
    }

    // MARK: - User message

    private var userMessage: some View {
        HStack {
            Spacer(minLength: 80)
            VStack(alignment: .trailing, spacing: 4) {
                Text(extractChatContent(message.content))
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.accentColor.opacity(0.85))
                    .foregroundStyle(.white)
                    .clipShape(BubbleShape(isUser: true))

                messageFooter(alignment: .trailing)
            }
        }
    }

    // MARK: - Assistant message

    private var assistantMessage: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                let displayContent = extractChatContent(message.content)
                Markdown(displayContent)
                    .textSelection(.enabled)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color(.controlBackgroundColor).opacity(0.6))
                    .clipShape(BubbleShape(isUser: false))
                    .overlay(
                        BubbleShape(isUser: false)
                            .strokeBorder(Color(.separatorColor).opacity(0.3), lineWidth: 0.5)
                    )

                messageFooter(alignment: .leading)
            }
            Spacer(minLength: 80)
        }
    }

    // MARK: - Footer

    private func messageFooter(alignment: HorizontalAlignment) -> some View {
        HStack(spacing: 6) {
            if let version = message.version {
                Text("v\(version)")
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundStyle(Color.accentColor.opacity(0.7))
            }
            Text(message.createdAt, style: .time)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 4)
    }

    private func extractChatContent(_ content: String) -> String {
        ResponseParser.parse(content).chat
    }
}

// MARK: - Bubble Shape

struct BubbleShape: Shape, @unchecked Sendable {
    let isUser: Bool

    func path(in rect: CGRect) -> Path {
        let radius: CGFloat = 16
        let tailRadius: CGFloat = 6

        var path = Path()

        if isUser {
            // User bubble: rounded with small tail on bottom-right
            path.addRoundedRect(
                in: CGRect(x: rect.minX, y: rect.minY,
                           width: rect.width, height: rect.height),
                cornerRadii: .init(
                    topLeading: radius,
                    bottomLeading: radius,
                    bottomTrailing: tailRadius,
                    topTrailing: radius
                )
            )
        } else {
            // Assistant bubble: rounded with small tail on bottom-left
            path.addRoundedRect(
                in: CGRect(x: rect.minX, y: rect.minY,
                           width: rect.width, height: rect.height),
                cornerRadii: .init(
                    topLeading: radius,
                    bottomLeading: tailRadius,
                    bottomTrailing: radius,
                    topTrailing: radius
                )
            )
        }

        return path
    }
}

extension BubbleShape: InsettableShape {
    func inset(by amount: CGFloat) -> some InsettableShape {
        InsetBubbleShape(isUser: isUser, insetAmount: amount)
    }
}

struct InsetBubbleShape: InsettableShape, @unchecked Sendable {
    let isUser: Bool
    let insetAmount: CGFloat

    func inset(by amount: CGFloat) -> InsetBubbleShape {
        InsetBubbleShape(isUser: isUser, insetAmount: insetAmount + amount)
    }

    func path(in rect: CGRect) -> Path {
        let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
        return BubbleShape(isUser: isUser).path(in: insetRect)
    }
}
