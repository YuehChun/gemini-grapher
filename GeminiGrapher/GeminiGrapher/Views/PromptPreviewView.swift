import SwiftUI

struct PromptPreviewView: View {
    @Bindable var chatVM: ChatViewModel

    var body: some View {
        VStack(spacing: 0) {
            // Header
            promptHeader
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(.bar)

            Divider()

            // Prompt content
            ScrollView {
                if let prompt = chatVM.displayedPrompt {
                    Text(prompt)
                        .font(.system(.body, design: .monospaced))
                        .lineSpacing(5)
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(20)
                } else {
                    emptyState
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .padding(20)
                }
            }

            // Version bar
            if !chatVM.promptVersions.isEmpty {
                Divider()
                versionBar
                    .background(.bar)
            }
        }
    }

    // MARK: - Header

    private var promptHeader: some View {
        HStack(spacing: 10) {
            Image(systemName: "text.quote")
                .foregroundStyle(.secondary)
            Text("Prompt")
                .font(.title3)
                .fontWeight(.semibold)

            Spacer()

            if chatVM.displayedVersion > 0 {
                Text("v\(chatVM.displayedVersion)")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.12))
                    .foregroundStyle(Color.accentColor)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }

            Button(action: { chatVM.copyPromptToClipboard() }) {
                Image(systemName: "doc.on.doc")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .disabled(chatVM.displayedPrompt == nil)
            .help("Copy prompt to clipboard")
        }
    }

    // MARK: - Empty state

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "text.quote")
                .font(.system(size: 36))
                .foregroundStyle(.quaternary)
            Text("Start a conversation to\ngenerate a prompt")
                .foregroundStyle(.tertiary)
                .font(.callout)
                .multilineTextAlignment(.center)
        }
    }

    // MARK: - Version bar

    private var versionBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chatVM.promptVersions, id: \.self) { version in
                    Button {
                        if chatVM.selectedVersion == version {
                            chatVM.selectedVersion = nil
                        } else {
                            chatVM.selectedVersion = version
                        }
                    } label: {
                        Text("v\(version)")
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                chatVM.displayedVersion == version
                                    ? Color.accentColor.opacity(0.15)
                                    : Color(.controlBackgroundColor)
                            )
                            .foregroundStyle(
                                chatVM.displayedVersion == version
                                    ? Color.accentColor
                                    : .secondary
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .strokeBorder(
                                        chatVM.displayedVersion == version
                                            ? Color.accentColor.opacity(0.3)
                                            : Color.clear,
                                        lineWidth: 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)
                }

                if chatVM.selectedVersion != nil {
                    Divider()
                        .frame(height: 16)

                    Button("Resume from v\(chatVM.selectedVersion!)") {
                        chatVM.resumeFromVersion(chatVM.selectedVersion!)
                    }
                    .font(.caption)
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
        }
    }
}
