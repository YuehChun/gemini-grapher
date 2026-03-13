import SwiftUI

struct PromptPreviewView: View {
    @Bindable var chatVM: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Prompt").font(.headline)
                Spacer()
                if chatVM.displayedVersion > 0 {
                    Text("v\(chatVM.displayedVersion)")
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color(.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 4))
                }
                Button(action: { chatVM.copyPromptToClipboard() }) {
                    Label("Copy", systemImage: "doc.on.doc")
                        .font(.caption)
                }
                .buttonStyle(.plain)
                .disabled(chatVM.displayedPrompt == nil)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            ScrollView {
                if let prompt = chatVM.displayedPrompt {
                    Text(prompt)
                        .font(.body)
                        .lineSpacing(4)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(16)
                } else {
                    VStack(spacing: 8) {
                        Image(systemName: "text.quote")
                            .font(.largeTitle)
                            .foregroundStyle(.secondary)
                        Text("Start a conversation to generate a prompt")
                            .foregroundStyle(.secondary)
                            .font(.callout)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(16)
                }
            }

            Divider()

            if !chatVM.promptVersions.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        Text("Versions")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        ForEach(chatVM.promptVersions, id: \.self) { version in
                            Button("v\(version)") {
                                if chatVM.selectedVersion == version {
                                    chatVM.selectedVersion = nil
                                } else {
                                    chatVM.selectedVersion = version
                                }
                            }
                            .buttonStyle(.plain)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(
                                chatVM.displayedVersion == version
                                    ? Color.accentColor.opacity(0.2)
                                    : Color(.controlBackgroundColor)
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 4))
                        }
                        if chatVM.selectedVersion != nil {
                            Button("Resume from v\(chatVM.selectedVersion!)") {
                                chatVM.resumeFromVersion(chatVM.selectedVersion!)
                            }
                            .font(.caption)
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(12)
                }
            }
        }
    }
}
