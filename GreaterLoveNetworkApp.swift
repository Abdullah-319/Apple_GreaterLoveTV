import SwiftUI
import Foundation
import AVKit

// MARK: - Models
struct LiveStream: Codable, Identifiable {
    let id = UUID()
    let _id: String
    let name: String
    let enabled: Bool
    let creation_time: String
    let embed_url: String?
    let hls_url: String?
    let thumbnail_url: String?
    let broadcasting_status: String?
    
    enum CodingKeys: String, CodingKey {
        case _id, name, enabled, creation_time, embed_url, hls_url, thumbnail_url, broadcasting_status
    }
}

struct Video: Codable, Identifiable {
    let id = UUID()
    let _id: String
    let name: String
    let enabled: Bool
    let type: String
    let creation_time: String
    let embed_url: String?
    let thumbnail_url: String?
    
    enum CodingKeys: String, CodingKey {
        case _id, name, enabled, type, creation_time, embed_url, thumbnail_url
    }
}

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let image: String
    let color: Color
}

struct Show: Identifiable {
    let id = UUID()
    let name: String
    let host: String
    let image: String
    let description: String
}

// MARK: - API Service
class CastrAPIService: ObservableObject {
    private let baseURL = "https://api.castr.com/v2"
    private let accessToken = "5aLoKjrNjly4"
    private let secretKey = "UjTCq8wOj76vjXznGFzdbMRzAkFq6VlJEl"
    
    @Published var liveStreams: [LiveStream] = []
    @Published var videos: [Video] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authHeader: String {
        let credentials = "\(accessToken):\(secretKey)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        return "Basic \(base64Credentials)"
    }
    
    func fetchLiveStreams() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/live_streams") else {
            loadMockData()
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("API Error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    self?.loadMockData()
                    return
                }
                
                if let data = data {
                    do {
                        // Handle both array and object responses
                        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            // If response is an object, look for data array
                            if let dataArray = jsonObject["data"] as? [[String: Any]] {
                                let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                                let streams = try JSONDecoder().decode([LiveStream].self, from: jsonData)
                                self?.liveStreams = streams
                            } else {
                                // If no data array, use mock data
                                self?.loadMockData()
                            }
                        } else if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                            // If response is directly an array
                            let streams = try JSONDecoder().decode([LiveStream].self, from: data)
                            self?.liveStreams = streams
                        } else {
                            self?.loadMockData()
                        }
                    } catch {
                        print("Decoding error: \(error)")
                        self?.errorMessage = "Failed to decode streams"
                        self?.loadMockData()
                    }
                } else {
                    self?.loadMockData()
                }
            }
        }.resume()
    }
    
    func fetchVideos() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/videos") else {
            loadMockVideos()
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    print("API Error: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    self?.loadMockVideos()
                    return
                }
                
                if let data = data {
                    do {
                        // Handle both array and object responses
                        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            // If response is an object, look for data array
                            if let dataArray = jsonObject["data"] as? [[String: Any]] {
                                let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                                let videos = try JSONDecoder().decode([Video].self, from: jsonData)
                                self?.videos = videos
                            } else {
                                // If no data array, use mock data
                                self?.loadMockVideos()
                            }
                        } else if let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                            // If response is directly an array
                            let videos = try JSONDecoder().decode([Video].self, from: data)
                            self?.videos = videos
                        } else {
                            self?.loadMockVideos()
                        }
                    } catch {
                        print("Decoding error: \(error)")
                        self?.errorMessage = "Failed to decode videos"
                        self?.loadMockVideos()
                    }
                } else {
                    self?.loadMockVideos()
                }
            }
        }.resume()
    }
    
    private func loadMockData() {
        liveStreams = [
            LiveStream(_id: "1", name: "Greater Love TV 1", enabled: true, creation_time: "2024-01-01", embed_url: nil, hls_url: nil, thumbnail_url: nil, broadcasting_status: "online"),
            LiveStream(_id: "2", name: "Greater Love TV 2", enabled: true, creation_time: "2024-01-01", embed_url: nil, hls_url: nil, thumbnail_url: nil, broadcasting_status: "online")
        ]
    }
    
    private func loadMockVideos() {
        videos = [
            Video(_id: "1", name: "Oasis Ministries", enabled: true, type: "vod", creation_time: "2024-01-01", embed_url: nil, thumbnail_url: nil),
            Video(_id: "2", name: "Jessica & Micah Wynn", enabled: true, type: "vod", creation_time: "2024-01-01", embed_url: nil, thumbnail_url: nil),
            Video(_id: "3", name: "Created To Praise", enabled: true, type: "vod", creation_time: "2024-01-01", embed_url: nil, thumbnail_url: nil)
        ]
    }
}

// MARK: - Main App Entry Point
@main
struct GreaterLoveNetworkApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Content View (Main Tab Controller)
struct ContentView: View {
    @StateObject private var apiService = CastrAPIService()
    @State private var selectedTab = 0
    @State private var selectedNavItem = "HOME"
    
    var body: some View {
        ZStack {
            // Sticky background image
            GeometryReader { geometry in
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(0.4)
                    .ignoresSafeArea()
            }
            
            VStack(spacing: 0) {
                // Fixed Navigation Bar
                NavigationBar(selectedItem: $selectedNavItem)
                
                // Content based on selected navigation
                Group {
                    switch selectedNavItem {
                    case "HOME":
                        HomeView()
                            .environmentObject(apiService)
                    case "ABOUT US":
                        AboutView()
                    case "ALL CATEGORIES":
                        CategoriesView()
                    case "CONNECT":
                        QRCodeGridView()
                    default:
                        HomeView()
                            .environmentObject(apiService)
                    }
                }
            }
        }
        .onAppear {
            apiService.fetchLiveStreams()
            apiService.fetchVideos()
        }
    }
}

// MARK: - Navigation Bar Component
struct NavigationBar: View {
    @Binding var selectedItem: String
    
    private let navItems = ["HOME", "ABOUT US", "ALL CATEGORIES", "CONNECT"]
    
    var body: some View {
        HStack {
            // Logo on the left
            Image("tvos_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 50)
                .padding(.leading, 80)
            
            Spacer()
            
            // Navigation items in the center
            HStack(spacing: 60) {
                ForEach(navItems, id: \.self) { item in
                    NavigationBarButton(
                        title: item,
                        isSelected: selectedItem == item
                    ) {
                        selectedItem = item
                    }
                }
            }
            
            Spacer()
        }
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Navigation Bar Button
struct NavigationBarButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .underline(isSelected, color: .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Rectangle()
                        .fill(Color.clear)
                        .overlay(
                            Rectangle()
                                .stroke(isFocused ? Color.white.opacity(0.3) : Color.clear, lineWidth: 2)
                                .cornerRadius(6)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Home View (Pixel Perfect Implementation)
struct HomeView: View {
    @EnvironmentObject var apiService: CastrAPIService
    @State private var selectedStream: LiveStream?
    @State private var showingVideoPlayer = false
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Dark background
                Color.black.ignoresSafeArea()
                
                // Background image positioned only in hero section
                VStack(spacing: 0) {
                    // Hero section with background image
                    ZStack {
                        // Background image only for hero section
                        Image("background")
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 800) // Fixed height for hero section
                            .clipped()
                            .opacity(0.6)
                        
                        // Hero content over background
                        headerSection(geometry: geometry)
                    }
                    
                    // Rest of content on solid background
                    VStack(spacing: 80) {
                        continueWatchingSection
                        categoriesSection
                        showsSection
                        liveStreamsSection
                    }
                    .padding(.horizontal, 80)
                    .padding(.bottom, 100)
                    .background(Color.black) // Solid background for content sections
                }
            }
        }
        .overlay(
            // Top Navigation Bar
            TopNavigationBar(selectedPage: "HOME"),
            alignment: .top
        )
        .sheet(isPresented: $showingVideoPlayer) {
            if let stream = selectedStream {
                LiveTVPlayerView(stream: stream)
            }
        }
    }
    
    private func headerSection(geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            // Space for top navigation bar
            Spacer()
                .frame(height: 120)
            
            // Hero section with main text
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        // Main headline
                        VStack(alignment: .leading, spacing: 8) {
                            Text("STREAM YOUR")
                                .font(.system(size: 72, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .kerning(-2)
                            
                            Text("FAVORITE")
                                .font(.system(size: 72, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .kerning(-2)
                            
                            Text("BIBLE TEACHERS")
                                .font(.system(size: 72, weight: .bold, design: .default))
                                .foregroundColor(.white)
                                .kerning(-2)
                        }
                        
                        Text("IN ONE PLACE")
                            .font(.system(size: 32, weight: .medium, design: .default))
                            .foregroundColor(.white)
                            .padding(.top, 30)
                        
                        // CTA Button
                        Button("Continue Watching") {
                            // Scroll to continue watching section
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 18)
                        .background(Color(red: 0.9, green: 0.2, blue: 0.2))
                        .cornerRadius(6)
                        .buttonStyle(PlainButtonStyle())
                        .padding(.top, 50)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 80)
                .padding(.bottom, 120)
            }
        }
    }
    
    private var continueWatchingSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                Text("Continue Watching")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    ContinueWatchingCard(title: "DAYSTAR", color: Color.teal)
                    ContinueWatchingCard(title: "CANADA", color: Color.blue)
                    ContinueWatchingCard(title: "ESPAÑOL", color: Color.pink)
                    ContinueWatchingCard(title: "ISRAEL", color: Color.cyan)
                    ContinueWatchingCard(title: "ESPAÑA", color: Color.green)
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Categories")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    CategoryCard(title: "All", subtitle: "All", imageName: "ministry_now")
                    CategoryCard(title: "Original", subtitle: "Original", imageName: "joni")
                    CategoryCard(title: "Live TV", subtitle: "Live TV", imageName: "rebecca")
                    CategoryCard(title: "Movies", subtitle: "Movies", imageName: "healing")
                    CategoryCard(title: "Web Series", subtitle: "Web Series", imageName: "marcus")
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var showsSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Shows")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 50) {
                    ShowCircleCard(
                        name: "Oasis Ministries",
                        host: "Anthony & Sheila Wynn",
                        color: Color.blue
                    )
                    ShowCircleCard(
                        name: "Jessica & Micah Wynn",
                        host: "Lead by The Word",
                        color: Color.purple
                    )
                    ShowCircleCard(
                        name: "Created To Praise",
                        host: "Tim Hill",
                        color: Color.green
                    )
                    ShowCircleCard(
                        name: "Manna-Fest",
                        host: "Perry Stone",
                        color: Color.orange
                    )
                    ShowCircleCard(
                        name: "Pace Assembly",
                        host: "Joey And Rita Rogers",
                        color: Color.red
                    )
                    ShowCircleCard(
                        name: "Word Of Life Ministry",
                        host: "Dr. Caesar Kalinowski",
                        color: Color.cyan
                    )
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var liveStreamsSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Live Streams Show")
                .font(.system(size: 24, weight: .medium))
                .foregroundColor(.white)
            
            HStack(spacing: 60) {
                LiveStreamCard(
                    title: "GREATER LOVE TV",
                    number: "1",
                    subtitle: "Greater Love Tv I"
                ) {
                    if let firstStream = apiService.liveStreams.first {
                        selectedStream = firstStream
                        showingVideoPlayer = true
                    }
                }
                
                LiveStreamCard(
                    title: "GREATER LOVE TV",
                    number: "2",
                    subtitle: "Greater Love Tv II"
                ) {
                    if apiService.liveStreams.count > 1 {
                        selectedStream = apiService.liveStreams[1]
                        showingVideoPlayer = true
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - Top Navigation Bar Component
struct TopNavigationBar: View {
    let selectedPage: String
    @State private var selectedTab = ""
    
    init(selectedPage: String) {
        self.selectedPage = selectedPage
        self._selectedTab = State(initialValue: selectedPage)
    }
    
    var body: some View {
        HStack {
            Spacer()
            
            // Centered Logo
            Image("tvos_logo")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 50)
            
            Spacer()
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 20)
        .background(Color.black.opacity(0.8))
        
        // Navigation Menu Below Logo
        HStack(spacing: 0) {
            Spacer()
            
            HStack(spacing: 60) {
                NavigationMenuButton(
                    title: "HOME",
                    isSelected: selectedTab == "HOME"
                ) {
                    selectedTab = "HOME"
                    // Navigate to home
                }
                
                NavigationMenuButton(
                    title: "ABOUT US",
                    isSelected: selectedTab == "ABOUT US"
                ) {
                    selectedTab = "ABOUT US"
                    // Navigate to about
                }
                
                NavigationMenuButton(
                    title: "ALL CATEGORIES",
                    isSelected: selectedTab == "ALL CATEGORIES"
                ) {
                    selectedTab = "ALL CATEGORIES"
                    // Navigate to categories
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 80)
        .padding(.vertical, 15)
        .background(Color.black.opacity(0.6))
    }
}

// MARK: - Navigation Menu Button
struct NavigationMenuButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(isSelected ? .white : .gray)
                .underline(isSelected, color: .white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(
                    Rectangle()
                        .fill(Color.clear)
                        .overlay(
                            Rectangle()
                                .stroke(isFocused ? Color.white.opacity(0.3) : Color.clear, lineWidth: 2)
                                .cornerRadius(6)
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Enhanced Card Components
struct ContinueWatchingCard: View {
    let title: String
    let color: Color
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: {}) {
            Rectangle()
                .fill(
                    LinearGradient(
                        colors: [color, color.opacity(0.7)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 300, height: 170)
                .overlay(
                    VStack {
                        Spacer()
                        Text(title)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.5), radius: 2)
                        Spacer()
                    }
                )
                .cornerRadius(12)
                .scaleEffect(isFocused ? 1.05 : 1.0)
                .shadow(color: isFocused ? .white.opacity(0.3) : .clear, radius: 8)
                .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
    }
}

struct CategoryCard: View {
    let title: String
    let subtitle: String
    let imageName: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 15) {
                Rectangle()
                    .fill(Color.gray.opacity(0.8))
                    .frame(width: 280, height: 158)
                    .overlay(
                        // Placeholder for actual image
                        Text(title)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    )
                    .cornerRadius(8)
                
                Text(subtitle)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: isFocused ? .white.opacity(0.3) : .clear, radius: 8)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
    }
}

struct ShowCircleCard: View {
    let name: String
    let host: String
    let color: Color
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 20) {
                // Circular show image
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [color, color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 140, height: 140)
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .overlay(
                        // Placeholder initials
                        Text(String(name.prefix(2)))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(spacing: 8) {
                    Text(name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 140)
                    
                    Text(host)
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 140)
                }
            }
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: isFocused ? .white.opacity(0.3) : .clear, radius: 8)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
    }
}

struct LiveStreamCard: View {
    let title: String
    let number: String
    let subtitle: String
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 25) {
                // Stream preview rectangle
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.2, green: 0.4, blue: 0.8),
                                Color(red: 0.1, green: 0.3, blue: 0.6)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 440, height: 248)
                    .overlay(
                        VStack(spacing: 10) {
                            Text(title)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(number)
                                .font(.system(size: 96, weight: .bold))
                                .foregroundColor(.white)
                        }
                    )
                    .cornerRadius(12)
                
                Text(subtitle)
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white)
            }
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: isFocused ? .white.opacity(0.3) : .clear, radius: 8)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
    }
}

// MARK: - Navigation Components
struct NavigationButton: View {
    let title: String
    let isSelected: Bool
    
    var body: some View {
        Text(title)
            .font(.system(size: 16, weight: .medium))
            .foregroundColor(isSelected ? .white : .gray)
            .underline(isSelected, color: .white)
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 80) {
                // Space for top navigation bar
                Spacer()
                    .frame(height: 140)
                
                // About content sections
                VStack(spacing: 100) {
                    // Hero section
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .aspectRatio(16/9, contentMode: .fit)
                        .overlay(
                            VStack(spacing: 20) {
                                Text("ABOUT GREATER LOVE")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                                Text("NETWORK TV")
                                    .font(.system(size: 48, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        )
                        .cornerRadius(12)
                        .padding(.horizontal, 80)
                    
                    // Mission & Vision
                    HStack(alignment: .top, spacing: 80) {
                        VStack(alignment: .leading, spacing: 30) {
                            Text("OUR MISSION & VISION")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("Greater Love Network Television has a singular goal; to reach souls with the good news of Jesus Christ.")
                                .font(.system(size: 22, weight: .medium))
                                .foregroundColor(.white)
                                .lineSpacing(8)
                            
                            Text("We seek out every available means of distribution to a world in need of hope. With an extensive blend of interdenominational and multi-cultural programming, we are committed to producing and providing quality television that will reach our viewers, refresh their lives, and renew their hearts.")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                                .lineSpacing(6)
                            
                            Button("CONTACT US") {
                                // Action
                            }
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 15)
                            .background(Color.red)
                            .cornerRadius(8)
                            .buttonStyle(PlainButtonStyle())
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .aspectRatio(4/3, contentMode: .fit)
                            .frame(maxWidth: 400)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 80)
                }
            }
        }
        .background(Color.black)
        .overlay(
            TopNavigationBar(selectedPage: "ABOUT US"),
            alignment: .top
        )
    }
}

// MARK: - Categories View
struct CategoriesView: View {
    private let categoryGrid = [
        [("All", "ministry_now"), ("Original", "joni"), ("Live TV", "rebecca"), ("Movies", "healing")],
        [("Web Series", "marcus"), ("Documentaries", "healing"), ("Kids", "rebecca"), ("Music", "joni")],
        [("Spanish", "marcus"), ("Teaching", "ministry_now"), ("Worship", "rebecca"), ("News", "healing")],
        [("Family", "joni"), ("Youth", "marcus"), ("Conferences", "ministry_now"), ("Special", "rebecca")]
    ]
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 80) {
                // Space for top navigation bar
                Spacer()
                    .frame(height: 140)
                
                // Categories title and grid
                VStack(alignment: .leading, spacing: 60) {
                    Text("ALL CATEGORIES")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 80)
                    
                    VStack(spacing: 50) {
                        ForEach(0..<categoryGrid.count, id: \.self) { rowIndex in
                            HStack(spacing: 50) {
                                ForEach(0..<categoryGrid[rowIndex].count, id: \.self) { columnIndex in
                                    let category = categoryGrid[rowIndex][columnIndex]
                                    CategoryCard(
                                        title: category.0,
                                        subtitle: category.0,
                                        imageName: category.1
                                    )
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 80)
                        }
                    }
                }
            }
        }
        .background(Color.black)
        .overlay(
            TopNavigationBar(selectedPage: "ALL CATEGORIES"),
            alignment: .top
        )
    }
}

// MARK: - QR Code Grid View
struct QRCodeGridView: View {
    private let qrCodes = [
        ("Donate", "Generate QR for donations"),
        ("Tell Your Story", "Share your testimony"),
        ("Prayer Request", "Submit prayer requests"),
        ("Download Mobile App", "Get the mobile app")
    ]
    
    var body: some View {
        VStack(spacing: 80) {
            // Space for top navigation bar
            Spacer()
                .frame(height: 140)
            
            // QR Code Grid
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 80),
                GridItem(.flexible(), spacing: 80)
            ], spacing: 100) {
                ForEach(0..<qrCodes.count, id: \.self) { index in
                    QRCodeView(title: qrCodes[index].0)
                }
            }
            .padding(.horizontal, 120)
            
            Spacer()
        }
        .background(Color.black)
        .overlay(
            TopNavigationBar(selectedPage: "CONNECT"),
            alignment: .top
        )
    }
}

// MARK: - QR Code Component
struct QRCodeView: View {
    let title: String
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: {
            // Handle QR code action
        }) {
            VStack(spacing: 30) {
                // QR Code placeholder
                Rectangle()
                    .fill(Color.white)
                    .frame(width: 280, height: 280)
                    .overlay(
                        // Simple QR code pattern simulation
                        VStack(spacing: 3) {
                            ForEach(0..<15, id: \.self) { row in
                                HStack(spacing: 3) {
                                    ForEach(0..<15, id: \.self) { col in
                                        Rectangle()
                                            .fill(Bool.random() ? Color.black : Color.white)
                                            .frame(width: 16, height: 16)
                                    }
                                }
                            }
                        }
                    )
                    .cornerRadius(12)
                
                Text(title)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .scaleEffect(isFocused ? 1.05 : 1.0)
            .shadow(color: isFocused ? .white.opacity(0.3) : .clear, radius: 8)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
    }
}

// MARK: - Video Player Views
struct VideoPlayerView: View {
    let videoURL: String?
    @State private var player: AVPlayer?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let urlString = videoURL, let url = URL(string: urlString) {
                VideoPlayer(player: player)
                    .onAppear {
                        player = AVPlayer(url: url)
                        player?.play()
                    }
                    .onDisappear {
                        player?.pause()
                        player = nil
                    }
            } else {
                VStack(spacing: 30) {
                    Image(systemName: "play.circle")
                        .font(.system(size: 100))
                        .foregroundColor(.gray)
                    
                    Text("Video not available")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.gray)
                }
            }
            
            // Back button overlay
            VStack {
                HStack {
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                }
                Spacer()
            }
            .padding(50)
        }
    }
}

struct LiveTVPlayerView: View {
    let stream: LiveStream
    @State private var player: AVPlayer?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let hlsURL = stream.hls_url, let url = URL(string: hlsURL) {
                VideoPlayer(player: player)
                    .onAppear {
                        player = AVPlayer(url: url)
                        player?.play()
                    }
                    .onDisappear {
                        player?.pause()
                        player = nil
                    }
            } else {
                // Enhanced fallback view
                VStack(spacing: 40) {
                    Image(systemName: "tv.circle")
                        .font(.system(size: 120))
                        .foregroundColor(.red)
                    
                    Text(stream.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("Live Stream")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.gray)
                    
                    if let status = stream.broadcasting_status {
                        HStack(spacing: 15) {
                            Circle()
                                .fill(status == "online" ? Color.green : Color.red)
                                .frame(width: 16, height: 16)
                            
                            Text(status.capitalized)
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    
                    // Mock streaming content rectangle
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.blue.opacity(0.3),
                                    Color.purple.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 900, height: 506)
                        .overlay(
                            VStack(spacing: 20) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 80))
                                    .foregroundColor(.white)
                                Text("Streaming Content")
                                    .font(.system(size: 28, weight: .medium))
                                    .foregroundColor(.white)
                            }
                        )
                        .cornerRadius(16)
                }
            }
            
            // Enhanced controls overlay
            VStack {
                HStack {
                    Button("Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 25)
                    .padding(.vertical, 12)
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(8)
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    Text(stream.name)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.black.opacity(0.8))
                        .cornerRadius(8)
                }
                
                Spacer()
            }
            .padding(50)
        }
    }
}

// MARK: - Settings View (Enhanced)
struct SettingsView: View {
    @State private var autoPlay = true
    @State private var highQuality = true
    @State private var notifications = true
    @State private var parentalControls = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 60) {
            // Space for top navigation bar
            Spacer()
                .frame(height: 140)
            
            Text("Settings")
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 20)
            
            VStack(alignment: .leading, spacing: 40) {
                SettingRow(title: "Auto Play", isOn: $autoPlay)
                SettingRow(title: "High Quality Streaming", isOn: $highQuality)
                SettingRow(title: "Push Notifications", isOn: $notifications)
                SettingRow(title: "Parental Controls", isOn: $parentalControls)
            }
            
            Spacer()
        }
        .padding(80)
        .background(Color.black)
        .overlay(
            TopNavigationBar(selectedPage: "SETTINGS"),
            alignment: .top
        )
    }
}

struct SettingRow: View {
    let title: String
    @Binding var isOn: Bool
    @FocusState private var isFocused: Bool
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(.white)
            
            Spacer()
            
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle())
                .accentColor(.red)
                .scaleEffect(1.2)
                .focused($isFocused)
        }
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isFocused ? Color.white.opacity(0.3) : Color.clear, lineWidth: 2)
                .fill(Color.clear)
        )
        .animation(.easeInOut(duration: 0.15), value: isFocused)
    }
}

// MARK: - Enhanced Focus Management and Accessibility
extension View {
    func tvOSFocusable() -> some View {
        self.buttonStyle(PlainButtonStyle())
    }
    
    func tvOSCard() -> some View {
        self.buttonStyle(CardButtonStyle())
    }
}

struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
