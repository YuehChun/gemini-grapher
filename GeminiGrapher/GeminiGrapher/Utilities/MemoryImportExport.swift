import Foundation
import AppKit

enum MemoryImportExport {
    static func exportMemory(from baseDir: URL) throws {
        let panel = NSSavePanel()
        panel.nameFieldStringValue = "memory-export.zip"
        panel.allowedContentTypes = [.zip]

        guard panel.runModal() == .OK, let destination = panel.url else { return }

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
        process.arguments = ["-c", "-k", "--sequesterRsrc", baseDir.path, destination.path]
        try process.run()
        process.waitUntilExit()

        guard process.terminationStatus == 0 else {
            throw MemoryIOError.exportFailed
        }
    }

    static func importMemory(to baseDir: URL) throws {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.zip, .folder]
        panel.canChooseDirectories = true
        panel.canChooseFiles = true

        guard panel.runModal() == .OK, let source = panel.url else { return }

        let sourceDir: URL
        if source.pathExtension == "zip" {
            let tempDir = FileManager.default.temporaryDirectory
                .appendingPathComponent("memory-import-\(UUID().uuidString)")
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/ditto")
            process.arguments = ["-x", "-k", source.path, tempDir.path]
            try process.run()
            process.waitUntilExit()
            guard process.terminationStatus == 0 else { throw MemoryIOError.importFailed }
            sourceDir = tempDir
        } else {
            sourceDir = source
        }

        let hasPrefs = FileManager.default.fileExists(
            atPath: sourceDir.appendingPathComponent("preferences").path
        )
        let hasFeedback = FileManager.default.fileExists(
            atPath: sourceDir.appendingPathComponent("feedback").path
        )
        guard hasPrefs || hasFeedback else {
            throw MemoryIOError.invalidStructure
        }

        let alert = NSAlert()
        alert.messageText = "Replace existing memory?"
        alert.informativeText = "This will replace all current memory files. This cannot be undone."
        alert.addButton(withTitle: "Replace")
        alert.addButton(withTitle: "Cancel")
        alert.alertStyle = .warning

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        if FileManager.default.fileExists(atPath: baseDir.path) {
            try FileManager.default.removeItem(at: baseDir)
        }
        try FileManager.default.copyItem(at: sourceDir, to: baseDir)
    }

    static func openInFinder(_ baseDir: URL) {
        try? FileManager.default.createDirectory(at: baseDir, withIntermediateDirectories: true)
        NSWorkspace.shared.open(baseDir)
    }
}

enum MemoryIOError: LocalizedError {
    case exportFailed
    case importFailed
    case invalidStructure

    var errorDescription: String? {
        switch self {
        case .exportFailed: return "Failed to export memory."
        case .importFailed: return "Failed to import memory archive."
        case .invalidStructure: return "Invalid memory folder. Must contain preferences/ or feedback/ subdirectory."
        }
    }
}
