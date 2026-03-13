import SwiftUI
import MarkdownUI

struct ChatView: View {
    @Bindable var chatVM: ChatViewModel
    let model: String

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(chatVM.currentSession?.name ?? "No Session")
                    .font(.headline)
                if chatVM.displayedVersion > 0 {
                    Text("v\(chatVM.displayedVersion)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        if let session = chatVM.currentSession {
                            ForEach(session.messages.sorted(by: { $0.createdAt < $1.createdAt })) { message in
                                MessageBubbleView(message: message)
                                    .id(message.id)
                            }
                        }
                        if chatVM.isStreaming && !chatVM.streamingChat.isEmpty {
                            HStack {
                                VStack(alignment: .leading) {
                                    Markdown(chatVM.streamingChat)
                                        .padding(10)
                                        .background(Color(.controlBackgroundColor))
                                        .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                                Spacer(minLength: 60)
                            }
                            .id("streaming")
                        }
                        if let error = chatVM.error {
                            HStack {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(error)
                                        .foregroundStyle(.red)
                                        .font(.callout)
                                    Button("Retry") {
                                        Task { await chatVM.retry(model: model) }
                                    }
                                    .buttonStyle(.bordered)
                                }
                                Spacer()
                            }
                            .padding(10)
                        }
                    }
                    .padding(16)
                }
                .onChange(of: chatVM.streamingChat) {
                    proxy.scrollTo("streaming", anchor: .bottom)
                }
            }

            Divider()

            HStack(spacing: 8) {
                TextField("Describe what you want to adjust...", text: $chatVM.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .lineLimit(1...5)
                    .onSubmit {
                        if !NSEvent.modifierFlags.contains(.shift) {
                            Task { await chatVM.send(model: model) }
                        }
                    }

                Button(action: {
                    Task { await chatVM.send(model: model) }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                }
                .buttonStyle(.plain)
                .disabled(chatVM.isStreaming || chatVM.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
        }
    }
}
