import Foundation

@Observable
class SettingsViewModel {
    var baseURL: String {
        didSet { UserDefaults.standard.set(baseURL, forKey: "vibeproxyURL") }
    }
    var selectedModel: String {
        didSet { UserDefaults.standard.set(selectedModel, forKey: "selectedModel") }
    }
    var availableModels: [String] = []
    var isLoadingModels = false

    init() {
        self.baseURL = UserDefaults.standard.string(forKey: "vibeproxyURL") ?? "http://localhost:8317"
        self.selectedModel = UserDefaults.standard.string(forKey: "selectedModel") ?? "claude-sonnet-4-6"
    }

    func fetchModels() async {
        isLoadingModels = true
        defer { isLoadingModels = false }

        let client = LLMClient(baseURL: baseURL)
        do {
            availableModels = try await client.fetchModels()
            if !availableModels.contains(selectedModel), let first = availableModels.first {
                selectedModel = first
            }
        } catch {
            availableModels = []
        }
    }
}
