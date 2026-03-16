import SwiftUI
import MarkdownUI

struct ChatView: View {
    @Bindable var chatVM: ChatViewModel
    let model: String
    @FocusState private var isInputFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            // Chat header
            chatHeader
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(.bar)

            Divider()

            // Messages area
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 16) {
                        if let session = chatVM.currentSession {
                            ForEach(session.messages.sorted(by: { $0.createdAt < $1.createdAt })) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                        }

                        // Streaming message
                        if chatVM.isStreaming && !chatVM.streamingChat.isEmpty {
                            HStack(alignment: .top) {
                                streamingBubble
                                Spacer(minLength: 80)
                            }
                            .id("streaming")
                        }

                        // Error display
                        if let error = chatVM.error {
                            errorView(error)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                }
                .scrollContentBackground(.hidden)
                .onChange(of: chatVM.streamingChat) {
                    withAnimation(.easeOut(duration: 0.15)) {
                        proxy.scrollTo("streaming", anchor: .bottom)
                    }
                }
            }

            Divider()

            // Input area
            inputArea
                .padding(16)
                .background(.bar)
        }
    }

    // MARK: - Header

    private var chatHeader: some View {
        HStack(spacing: 8) {
            Text(chatVM.currentSession?.name ?? "No Session")
                .font(.title3)
                .fontWeight(.semibold)

            if chatVM.displayedVersion > 0 {
                versionBadge(chatVM.displayedVersion)
            }

            Spacer()

            if chatVM.isStreaming {
                ProgressView()
                    .controlSize(.small)
                    .padding(.trailing, 4)
            }
        }
    }

    // MARK: - Streaming bubble

    private var streamingBubble: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 6) {
                Circle()
                    .fill(.green)
                    .frame(width: 6, height: 6)
                Text("Assistant")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Markdown(chatVM.streamingChat)
                .padding(12)
                .background(Color(.controlBackgroundColor).opacity(0.6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color(.separatorColor).opacity(0.3), lineWidth: 0.5)
                )
        }
    }

    // MARK: - Error view

    private func errorView(_ error: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            VStack(alignment: .leading, spacing: 4) {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.callout)
                Button("Retry") {
                    Task { await chatVM.retry(model: model) }
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            Spacer()
        }
        .padding(12)
        .background(Color.red.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    // MARK: - Input area

    private var inputArea: some View {
        HStack(alignment: .bottom, spacing: 12) {
            TextEditor(text: $chatVM.inputText)
                .font(.body)
                .scrollContentBackground(.hidden)
                .padding(10)
                .frame(minHeight: 60, maxHeight: 160)
                .fixedSize(horizontal: false, vertical: true)
                .background(Color(.textBackgroundColor).opacity(0.5))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            isInputFocused ? Color.accentColor.opacity(0.5) : Color(.separatorColor).opacity(0.4),
                            lineWidth: isInputFocused ? 1.5 : 0.5
                        )
                )
                .overlay(alignment: .topLeading) {
                    if chatVM.inputText.isEmpty {
                        Text("Describe what you want to adjust...")
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 18)
                            .allowsHitTesting(false)
                    }
                }
                .focused($isInputFocused)

            Button(action: {
                Task { await chatVM.send(model: model) }
            }) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(
                        canSend ? Color.accentColor : Color(.tertiaryLabelColor)
                    )
            }
            .buttonStyle(.plain)
            .disabled(!canSend)
            .keyboardShortcut(.return, modifiers: .command)
            .padding(.bottom, 6)
        }
    }

    // MARK: - Helpers

    private var canSend: Bool {
        !chatVM.isStreaming && !chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func versionBadge(_ version: Int) -> some View {
        Text("v\(version)")
            .font(.caption)
            .fontWeight(.medium)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.12))
            .foregroundStyle(Color.accentColor)
            .clipShape(RoundedRectangle(cornerRadius: 6))
    }
}
