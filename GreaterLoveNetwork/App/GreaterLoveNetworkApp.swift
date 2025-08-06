import SwiftUI

@main
struct GreaterLoveNetworkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .onAppear {
                    // Initialize the progress manager on app launch
                    _ = WatchProgressManager.shared
                }
        }
    }
}
