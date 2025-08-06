import SwiftUI

// MARK: - Content View with Progress Manager
struct ContentView: View {
    @StateObject private var apiService = CastrAPIService()
    @StateObject private var progressManager = WatchProgressManager.shared
    @State private var selectedNavItem = "HOME"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(0.4)
                    .ignoresSafeArea()
                
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.6)
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    NavigationBar(selectedItem: $selectedNavItem)
                    
                    ScrollView {
                        Group {
                            switch selectedNavItem {
                            case "HOME":
                                HomeView()
                                    .environmentObject(apiService)
                                    .environmentObject(progressManager)
                            case "ABOUT US":
                                AboutView()
                            case "ALL CATEGORIES":
                                CategoriesView()
                                    .environmentObject(apiService)
                                    .environmentObject(progressManager)
                            default:
                                HomeView()
                                    .environmentObject(apiService)
                                    .environmentObject(progressManager)
                            }
                        }
                    }
                }
            }
        }
        .onAppear {
            apiService.fetchAllContent()
        }
    }
}
