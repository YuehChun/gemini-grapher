import SwiftUI

struct SettingsView: View {
    @State private var vm = SettingsViewModel()

    var body: some View {
        Form {
            Section("VibeProxy") {
                TextField("Base URL", text: $vm.baseURL)
                    .textFieldStyle(.roundedBorder)
            }

            Section("Model") {
                Picker("Model", selection: $vm.selectedModel) {
                    if vm.availableModels.isEmpty {
                        Text(vm.selectedModel).tag(vm.selectedModel)
                    }
                    ForEach(vm.availableModels, id: \.self) { model in
                        Text(model).tag(model)
                    }
                }

                Button(vm.isLoadingModels ? "Loading..." : "Refresh Models") {
                    Task { await vm.fetchModels() }
                }
                .disabled(vm.isLoadingModels)
            }

            Section("Memory") {
                HStack {
                    Text("Folder:")
                    Text(MemoryStore().baseDirectory.path)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                        .truncationMode(.middle)
                }
                Button("Open in Finder") {
                    MemoryImportExport.openInFinder(MemoryStore().baseDirectory)
                }
            }
        }
        .formStyle(.grouped)
        .frame(width: 450, height: 320)
        .task { await vm.fetchModels() }
    }
}
