import SwiftUI

struct ContentView: View {
    var body: some View {
        NavigationSplitView {
            Text("Sessions")
        } content: {
            Text("Chat")
        } detail: {
            Text("Prompt Preview")
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
