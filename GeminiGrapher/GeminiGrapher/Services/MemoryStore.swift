import Foundation

class MemoryStore {
    let baseDirectory: URL

    init(baseDirectory: URL? = nil) {
        if let dir = baseDirectory {
            self.baseDirectory = dir
        } else {
            self.baseDirectory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
                .appendingPathComponent("GeminiGrapher")
                .appendingPathComponent("memory")
        }
    }

    private var preferencesDirectory: URL {
        baseDirectory.appendingPathComponent("preferences")
    }

    private var feedbackDirectory: URL {
        baseDirectory.appendingPathComponent("feedback")
    }

    func loadPreferences() -> String {
        guard FileManager.default.fileExists(atPath: preferencesDirectory.path) else { return "" }
        let files = (try? FileManager.default.contentsOfDirectory(at: preferencesDirectory, includingPropertiesForKeys: nil)) ?? []
        return files
            .filter { $0.pathExtension == "md" }
            .sorted { $0.lastPathComponent < $1.lastPathComponent }
            .compactMap { try? String(contentsOf: $0, encoding: .utf8) }
            .joined(separator: "\n\n")
    }

    func savePreferences(filename: String, content: String) throws {
        try FileManager.default.createDirectory(at: preferencesDirectory, withIntermediateDirectories: true)
        let path = preferencesDirectory.appendingPathComponent(filename)
        try content.write(to: path, atomically: true, encoding: .utf8)
    }

    func listPreferenceFiles() -> [URL] {
        (try? FileManager.default.contentsOfDirectory(at: preferencesDirectory, includingPropertiesForKeys: nil))?.filter { $0.pathExtension == "md" } ?? []
    }

    func loadFeedback(for sessionId: UUID) -> String {
        let path = feedbackDirectory.appendingPathComponent("\(sessionId.uuidString).md")
        return (try? String(contentsOf: path, encoding: .utf8)) ?? ""
    }

    func saveFeedback(for sessionId: UUID, sessionName: String, content: String) throws {
        try FileManager.default.createDirectory(at: feedbackDirectory, withIntermediateDirectories: true)
        let path = feedbackDirectory.appendingPathComponent("\(sessionId.uuidString).md")
        let fullContent = "# \(sessionName)\n\n\(content)"
        try fullContent.write(to: path, atomically: true, encoding: .utf8)
    }

    func deleteFeedback(for sessionId: UUID) {
        let path = feedbackDirectory.appendingPathComponent("\(sessionId.uuidString).md")
        try? FileManager.default.removeItem(at: path)
    }
}
