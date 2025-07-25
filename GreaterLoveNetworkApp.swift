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
    let ingest: Ingest?
    let playback: Playback?
    
    enum CodingKeys: String, CodingKey {
        case _id, name, enabled, creation_time, embed_url, hls_url, thumbnail_url, broadcasting_status, ingest, playback
    }
}

struct Ingest: Codable {
    let server: String
    let key: String
}

struct Playback: Codable {
    let hls_url: String?
    let embed_url: String?
    let embed_audio_url: String?
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
    let hls_url: String?
    let playback: VideoPlayback?
    
    enum CodingKeys: String, CodingKey {
        case _id, name, enabled, type, creation_time, embed_url, thumbnail_url, hls_url, playback
    }
}

struct VideoPlayback: Codable {
    let embed_url: String?
    let hls_url: String?
}

struct Recording: Codable, Identifiable {
    let id = UUID()
    let _id: String?
    let videoFolderId: String?
    let recordingId: String?
    let name: String
    let from: Int?
    let duration: Int?
    let bytes: Int?
    let status: String?
    let creationTime: String?
    let playback: RecordingPlayback?
    
    enum CodingKeys: String, CodingKey {
        case _id, videoFolderId, recordingId = "id", name, from, duration, bytes, status, creationTime, playback
    }
}

struct RecordingPlayback: Codable {
    let embed_url: String?
    let hls_url: String?
}

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let image: String
    let color: Color
    let videos: [Video]
}

// MARK: - Additional Models for VOD
struct Folder: Codable, Identifiable {
    let id = UUID()
    let _id: String
    let name: String
    let description: String?
    let created_at: String?
    let updated_at: String?
    let files: [VODFile]?
    
    enum CodingKeys: String, CodingKey {
        case _id, name, description, created_at, updated_at, files
    }
}

struct VODFile: Codable, Identifiable {
    let id = UUID()
    let _id: String
    let name: String
    let description: String?
    let duration: Int?
    let size: Int?
    let status: String?
    let created_at: String?
    let thumbnail_url: String?
    let playback: VODPlayback?
    
    enum CodingKeys: String, CodingKey {
        case _id, name, description, duration, size, status, created_at, thumbnail_url, playback
    }
}

struct VODPlayback: Codable {
    let embed_url: String?
    let hls_url: String?
}

// MARK: - API Service
class CastrAPIService: ObservableObject {
    private let baseURL = "https://api.castr.com/v2"
    private let accessToken = "5aLoKjrNjly4"
    private let secretKey = "UjTCq8wOj76vjXznGFzdbMRzAkFq6VlJEl"
    
    @Published var liveStreams: [LiveStream] = []
    @Published var videos: [Video] = []
    @Published var vodFiles: [VODFile] = []
    @Published var folders: [Folder] = []
    @Published var recordings: [Recording] = []
    @Published var categories: [Category] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private var authHeader: String {
        let credentials = "\(accessToken):\(secretKey)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        return "Basic \(base64Credentials)"
    }
    
    func fetchAllContent() {
        fetchLiveStreams()
        fetchFolders()
    }
    
    func fetchFolders() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/folders") else {
            handleError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleError("API Error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.handleError("No data received")
                    return
                }
                
                do {
                    // Try direct array decode first
                    let folders = try JSONDecoder().decode([Folder].self, from: data)
                    self?.folders = folders
                    self?.fetchAllVideosFromFolders(folders)
                    self?.isLoading = false
                } catch {
                    print("Folders Decoding error: \(error)")
                    // Try to parse as object with data array
                    do {
                        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let dataArray = jsonObject["data"] as? [[String: Any]] {
                                let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                                let folders = try JSONDecoder().decode([Folder].self, from: jsonData)
                                self?.folders = folders
                                self?.fetchAllVideosFromFolders(folders)
                            } else if let foldersArray = jsonObject["folders"] as? [[String: Any]] {
                                let jsonData = try JSONSerialization.data(withJSONObject: foldersArray)
                                let folders = try JSONDecoder().decode([Folder].self, from: jsonData)
                                self?.folders = folders
                                self?.fetchAllVideosFromFolders(folders)
                            } else {
                                self?.handleError("Failed to decode folders")
                            }
                        } else {
                            self?.handleError("Invalid JSON structure")
                        }
                    } catch {
                        self?.handleError("Parsing error: \(error.localizedDescription)")
                    }
                    self?.isLoading = false
                }
            }
        }.resume()
    }
    
    func fetchAllVideosFromFolders(_ folders: [Folder]) {
        var allVODFiles: [VODFile] = []
        
        for folder in folders {
            fetchFolderDetail(folderId: folder._id) { vodFiles in
                allVODFiles.append(contentsOf: vodFiles)
                DispatchQueue.main.async {
                    self.vodFiles = allVODFiles
                    self.createCategoriesFromVOD(from: allVODFiles)
                }
            }
        }
    }
    
    func fetchFolderDetail(folderId: String, completion: @escaping ([VODFile]) -> Void) {
        guard let url = URL(string: "\(baseURL)/folders/\(folderId)") else {
            completion([])
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion([])
                return
            }
            
            do {
                let folder = try JSONDecoder().decode(Folder.self, from: data)
                completion(folder.files ?? [])
            } catch {
                print("Folder detail decoding error: \(error)")
                // Try alternate structure
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let filesArray = jsonObject["files"] as? [[String: Any]] {
                        let jsonData = try JSONSerialization.data(withJSONObject: filesArray)
                        let vodFiles = try JSONDecoder().decode([VODFile].self, from: jsonData)
                        completion(vodFiles)
                    } else {
                        completion([])
                    }
                } catch {
                    completion([])
                }
            }
        }.resume()
    }
    
    func fetchLiveStreams() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/live_streams") else {
            handleError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleError("API Error: \(error.localizedDescription)")
                    return
                }
                
                guard let data = data else {
                    self?.handleError("No data received")
                    return
                }
                
                do {
                    let streams = try JSONDecoder().decode([LiveStream].self, from: data)
                    self?.liveStreams = streams.filter { $0.enabled }
                    self?.isLoading = false
                } catch {
                    print("Live Streams Decoding error: \(error)")
                    // Try to parse as object with data array
                    do {
                        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                           let dataArray = jsonObject["data"] as? [[String: Any]] {
                            let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                            let streams = try JSONDecoder().decode([LiveStream].self, from: jsonData)
                            self?.liveStreams = streams.filter { $0.enabled }
                        } else {
                            self?.handleError("Failed to decode live streams")
                        }
                    } catch {
                        self?.handleError("Parsing error: \(error.localizedDescription)")
                    }
                    self?.isLoading = false
                }
            }
        }.resume()
    }
    
    func fetchVideos() {
        // This method is now deprecated, using fetchFolders instead
        // Keeping for backward compatibility but not using
        print("fetchVideos method deprecated - using fetchFolders instead")
    }
    
    func fetchRecordings(for streamId: String) {
        guard let url = URL(string: "\(baseURL)/live_streams/\(streamId)/recordings") else {
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                guard let data = data, error == nil else { return }
                
                do {
                    let recordings = try JSONDecoder().decode([Recording].self, from: data)
                    self?.recordings.append(contentsOf: recordings)
                } catch {
                    print("Recordings Decoding error: \(error)")
                }
            }
        }.resume()
    }
    
    private func createCategoriesFromVOD(from vodFiles: [VODFile]) {
        let allFiles = vodFiles.filter { $0.status == "completed" || $0.status == "ready" }
        
        // Convert VODFiles to Video format for compatibility
        let convertedVideos = allFiles.map { vodFile in
            Video(
                _id: vodFile._id,
                name: vodFile.name,
                enabled: true,
                type: "vod",
                creation_time: vodFile.created_at ?? "",
                embed_url: vodFile.playback?.embed_url,
                thumbnail_url: vodFile.thumbnail_url,
                hls_url: vodFile.playback?.hls_url,
                playback: VideoPlayback(
                    embed_url: vodFile.playback?.embed_url,
                    hls_url: vodFile.playback?.hls_url
                )
            )
        }
        
        self.videos = convertedVideos
        
        categories = [
            Category(name: "All", image: "ministry_now", color: .blue, videos: convertedVideos),
            Category(name: "Original", image: "joni", color: .purple, videos: convertedVideos.filter { $0.type == "vod" }),
            Category(name: "Live TV", image: "rebecca", color: .red, videos: convertedVideos.filter { $0.type == "live" }),
            Category(name: "Movies", image: "healing", color: .green, videos: convertedVideos.filter { $0.name.lowercased().contains("movie") }),
            Category(name: "Web Series", image: "marcus", color: .orange, videos: convertedVideos.filter { $0.name.lowercased().contains("series") })
        ]
    }
    
    private func createCategories(from videos: [Video]) {
        let allVideos = videos
        
        categories = [
            Category(name: "All", image: "ministry_now", color: .blue, videos: allVideos),
            Category(name: "Original", image: "joni", color: .purple, videos: allVideos.filter { $0.type == "vod" }),
            Category(name: "Live TV", image: "rebecca", color: .red, videos: allVideos.filter { $0.type == "live" }),
            Category(name: "Movies", image: "healing", color: .green, videos: allVideos.filter { $0.name.lowercased().contains("movie") }),
            Category(name: "Web Series", image: "marcus", color: .orange, videos: allVideos.filter { $0.name.lowercased().contains("series") })
        ]
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        isLoading = false
        print("Error: \(message)")
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

// MARK: - Content View (Main Controller)
struct ContentView: View {
    @StateObject private var apiService = CastrAPIService()
    @State private var selectedNavItem = "HOME"
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Fixed background image (sticky positioning)
                Image("background")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .opacity(0.4)
                    .ignoresSafeArea()
                    .onAppear {
                        // If background image doesn't exist, use gradient fallback
                    }
                
                // Fallback gradient background if image doesn't load
                LinearGradient(
                    colors: [Color.black, Color.gray.opacity(0.3), Color.black],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .opacity(0.6)
                .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Fixed Navigation Bar
                    NavigationBar(selectedItem: $selectedNavItem)
                    
                    // Scrollable Content based on selected navigation
                    ScrollView {
                        Group {
                            switch selectedNavItem {
                            case "HOME":
                                HomeView()
                                    .environmentObject(apiService)
                            case "ABOUT US":
                                AboutView()
                            case "ALL CATEGORIES":
                                CategoriesView()
                                    .environmentObject(apiService)
                            default:
                                HomeView()
                                    .environmentObject(apiService)
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

// MARK: - Navigation Bar Component
struct NavigationBar: View {
    @Binding var selectedItem: String
    
    private let navItems = ["HOME", "ABOUT US", "ALL CATEGORIES"]
    
    var body: some View {
        HStack {
            // Logo on the left
            VStack(alignment: .leading, spacing: 4) {
                Text("GREATERLOVE")
                    .font(.custom("Poppins-Bold", size: 18))
                    .foregroundColor(.white)
                    .kerning(1.5)
                
                Rectangle()
                    .fill(Color.white)
                    .frame(height: 2)
                    .frame(width: 140)
                
                Text("NETWORK")
                    .font(.custom("Poppins-Medium", size: 10))
                    .foregroundColor(.white)
                    .kerning(3)
            }
            .padding(.leading, 60)
            
            Spacer()
            
            // Navigation items in the center-right area
            HStack(spacing: 80) {
                ForEach(navItems, id: \.self) { item in
                    NavigationBarButton(
                        title: item,
                        isSelected: selectedItem == item
                    ) {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            selectedItem = item
                        }
                    }
                }
            }
            .padding(.trailing, 60)
            
            Spacer()
        }
        .padding(.vertical, 25)
        .background(
            Color.black.opacity(0.95)
        )
        .zIndex(1)
    }
}

// MARK: - Navigation Bar Button
struct NavigationBarButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
                    .kerning(0.5)
                
                // Dot indicator for selected state
                if isSelected {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 4, height: 4)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(isSelected ? Color.white.opacity(0.3) : Color.clear, lineWidth: 1)
                    .fill(isSelected ? Color.white.opacity(0.05) : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var apiService: CastrAPIService
    @State private var selectedContent: Any?
    @State private var showingVideoPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Hero section with main text
            headerSection()
            
            // Main content sections with semi-transparent background
            VStack(spacing: 80) {
                continueWatchingSection
                categoriesSection
                showsSection
                liveStreamsSection
            }
            .padding(.horizontal, 80)
            .padding(.bottom, 100)
            .background(Color.black.opacity(0.8))
        }
        .sheet(isPresented: $showingVideoPlayer) {
            if let stream = selectedContent as? LiveStream {
                LiveTVPlayerView(stream: stream)
            } else if let video = selectedContent as? Video {
                VideoPlayerView(video: video)
            }
        }
    }
    
    private func headerSection() -> some View {
        VStack(spacing: 0) {
            // Space for fixed navigation bar
            Spacer()
                .frame(height: 40)
            
            // Hero section with main text
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
                        // Main headline
                        VStack(alignment: .leading, spacing: 8) {
                            Text("STREAM YOUR")
                                .font(.custom("Poppins-Bold", size: 72))
                                .foregroundColor(.white)
                                .kerning(-2)
                            
                            Text("FAVORITE")
                                .font(.custom("Poppins-Bold", size: 72))
                                .foregroundColor(.white)
                                .kerning(-2)
                            
                            Text("BIBLE TEACHERS")
                                .font(.custom("Poppins-Bold", size: 72))
                                .foregroundColor(.white)
                                .kerning(-2)
                        }
                        
                        Text("IN ONE PLACE")
                            .font(.custom("Poppins-Medium", size: 32))
                            .foregroundColor(.white)
                            .padding(.top, 30)
                        
                        // CTA Button
                        Button("Continue Watching") {
                            // Scroll to continue watching section
                        }
                        .font(.custom("Poppins-SemiBold", size: 18))
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
                .padding(.bottom, 80)
            }
        }
        .frame(height: 500)
    }
    
    private var continueWatchingSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            HStack {
                Text("Continue Watching")
                    .font(.custom("Poppins-Medium", size: 24))
                    .foregroundColor(.white)
                Spacer()
            }
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    if apiService.isLoading || apiService.videos.isEmpty {
                        // Show loading placeholders
                        ForEach(0..<5, id: \.self) { _ in
                            LoadingCard()
                        }
                    } else {
                        ForEach(Array(apiService.videos.prefix(5))) { video in
                            VideoCard(video: video) {
                                selectedContent = video
                                showingVideoPlayer = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var categoriesSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Categories")
                .font(.custom("Poppins-Medium", size: 24))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 30) {
                    if apiService.isLoading || apiService.categories.isEmpty {
                        // Show loading placeholders
                        ForEach(0..<5, id: \.self) { _ in
                            LoadingCategoryCard()
                        }
                    } else {
                        ForEach(apiService.categories) { category in
                            CategoryCard(category: category)
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var showsSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Shows")
                .font(.custom("Poppins-Medium", size: 24))
                .foregroundColor(.white)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 50) {
                    if apiService.isLoading || apiService.videos.isEmpty {
                        // Show loading placeholders
                        ForEach(0..<6, id: \.self) { index in
                            LoadingShowCard(color: [Color.blue, Color.purple, Color.green, Color.orange, Color.red, Color.cyan][index])
                        }
                    } else {
                        ForEach(Array(apiService.videos.prefix(6).enumerated()), id: \.element.id) { index, video in
                            let colors: [Color] = [.blue, .purple, .green, .orange, .red, .cyan]
                            ShowCircleCard(
                                video: video,
                                color: colors[index % colors.count]
                            ) {
                                selectedContent = video
                                showingVideoPlayer = true
                            }
                        }
                    }
                }
                .padding(.horizontal, 40)
            }
        }
    }
    
    private var liveStreamsSection: some View {
        VStack(alignment: .leading, spacing: 40) {
            Text("Live Streams Show")
                .font(.custom("Poppins-Medium", size: 24))
                .foregroundColor(.white)
            
            HStack(spacing: 60) {
                if apiService.isLoading || apiService.liveStreams.isEmpty {
                    // Show loading placeholders
                    LoadingLiveStreamCard(number: "1", subtitle: "Greater Love Tv I")
                    LoadingLiveStreamCard(number: "2", subtitle: "Greater Love Tv II")
                } else {
                    ForEach(Array(apiService.liveStreams.prefix(2).enumerated()), id: \.element.id) { index, stream in
                        LiveStreamCard(
                            stream: stream,
                            number: "\(index + 1)",
                            subtitle: "Greater Love Tv \(index == 0 ? "I" : "II")"
                        ) {
                            selectedContent = stream
                            showingVideoPlayer = true
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.horizontal, 40)
        }
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 80) {
            // Space for fixed navigation bar
            Spacer()
                .frame(height: 40)
            
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
                
                // Donation Section
                VStack(spacing: 40) {
                    Text("DONATE NOW")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                    
                    Text("HELP OTHERS STAND STRONG IN FAITH")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Around the world, and right where you live, people are desperate for something that will bring them peace, purpose, and a buffer from the confusion all around them. Of course, the only answer is Jesus. And here at Greater Love Network, through the partnership of friends like you, we're taking the message of His salvation and hope to millions every day.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 100)
                    
                    VStack(spacing: 20) {
                        HStack {
                            Text("GREATERLOVE")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                            Rectangle()
                                .fill(Color.white)
                                .frame(height: 2)
                                .frame(width: 100)
                            Text("NETWORK")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white)
                                .kerning(1)
                        }
                        
                        Text("THANK YOU FOR STANDING WITH US!")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundColor(.white)
                        
                        Button("DONATE NOW") {
                            // Action
                        }
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 15)
                        .background(Color.white)
                        .cornerRadius(8)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
                .padding(80)
                .background(Color.black.opacity(0.9))
            }
        }
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Categories View
struct CategoriesView: View {
    @EnvironmentObject var apiService: CastrAPIService
    
    var body: some View {
        VStack(alignment: .leading, spacing: 80) {
            // Space for fixed navigation bar
            Spacer()
                .frame(height: 40)
            
            // Categories title and grid
            VStack(alignment: .leading, spacing: 60) {
                Text("ALL CATEGORIES")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 80)
                
                if apiService.isLoading || apiService.categories.isEmpty {
                    // Loading state
                    VStack(spacing: 50) {
                        ForEach(0..<4, id: \.self) { _ in
                            HStack(spacing: 50) {
                                ForEach(0..<4, id: \.self) { _ in
                                    LoadingCategoryCard()
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 80)
                        }
                    }
                } else {
                    // Dynamic content
                    LazyVGrid(columns: [
                        GridItem(.flexible(), spacing: 50),
                        GridItem(.flexible(), spacing: 50),
                        GridItem(.flexible(), spacing: 50),
                        GridItem(.flexible(), spacing: 50)
                    ], spacing: 50) {
                        ForEach(apiService.categories) { category in
                            CategoryDetailCard(category: category)
                        }
                    }
                    .padding(.horizontal, 80)
                }
            }
        }
        .background(Color.black.opacity(0.8))
    }
}

// MARK: - Card Components
struct VideoCard: View {
    let video: Video
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                AsyncImage(url: URL(string: video.thumbnail_url ?? "")) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    Rectangle()
                        .fill(Color.gray.opacity(0.6))
                        .overlay(
                            Image(systemName: "play.circle")
                                .font(.system(size: 40))
                                .foregroundColor(.white)
                        )
                }
                .frame(width: 300, height: 170)
                .cornerRadius(12)
                .clipped()
                
                Text(video.name)
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryCard: View {
    let category: Category
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 15) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [category.color, category.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 158)
                    .overlay(
                        VStack {
                            Text(category.name)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(.white)
                            
                            Text("\(category.videos.count) videos")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    )
                    .cornerRadius(8)
                
                Text(category.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct CategoryDetailCard: View {
    let category: Category
    
    var body: some View {
        Button(action: {}) {
            VStack(spacing: 15) {
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [category.color, category.color.opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 280, height: 158)
                    .overlay(
                        VStack {
                            Text(category.name)
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text("\(category.videos.count) videos")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.9))
                        }
                    )
                    .cornerRadius(8)
                
                Text(category.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ShowCircleCard: View {
    let video: Video
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
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
                        // Show initials from video name
                        Text(String(video.name.prefix(2).uppercased()))
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    )
                
                VStack(spacing: 8) {
                    Text(video.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 140)
                    
                    Text(video.type.uppercased())
                        .font(.system(size: 12, weight: .regular))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .lineLimit(1)
                        .frame(width: 140)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct LiveStreamCard: View {
    let stream: LiveStream
    let number: String
    let subtitle: String
    let action: () -> Void
    
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
                            Text("GREATER LOVE TV")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            
                            Text(number)
                                .font(.system(size: 96, weight: .bold))
                                .foregroundColor(.white)
                            
                            // Live status indicator
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(stream.broadcasting_status == "online" ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                
                                Text(stream.broadcasting_status?.uppercased() ?? "OFFLINE")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    )
                    .cornerRadius(12)
                
                VStack(spacing: 5) {
                    Text(subtitle)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(stream.name)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Loading Components
struct LoadingCard: View {
    var body: some View {
        VStack(spacing: 15) {
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 300, height: 170)
                .cornerRadius(12)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                )
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 200, height: 20)
                .cornerRadius(4)
        }
    }
}

struct LoadingCategoryCard: View {
    var body: some View {
        VStack(spacing: 15) {
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 280, height: 158)
                .cornerRadius(8)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                )
            
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(width: 120, height: 16)
                .cornerRadius(4)
        }
    }
}

struct LoadingShowCard: View {
    let color: Color
    
    var body: some View {
        VStack(spacing: 20) {
            Circle()
                .fill(color.opacity(0.4))
                .frame(width: 140, height: 140)
                .overlay(
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                )
            
            VStack(spacing: 8) {
                Rectangle()
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 120, height: 16)
                    .cornerRadius(4)
                
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
                    .frame(width: 80, height: 12)
                    .cornerRadius(4)
            }
        }
    }
}

struct LoadingLiveStreamCard: View {
    let number: String
    let subtitle: String
    
    var body: some View {
        VStack(spacing: 25) {
            Rectangle()
                .fill(Color.gray.opacity(0.4))
                .frame(width: 440, height: 248)
                .overlay(
                    VStack(spacing: 10) {
                        Text("GREATER LOVE TV")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text(number)
                            .font(.system(size: 96, weight: .bold))
                            .foregroundColor(.white.opacity(0.7))
                        
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    }
                )
                .cornerRadius(12)
            
            Text(subtitle)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Video Player Views
struct VideoPlayerView: View {
    let video: Video
    @State private var player: AVPlayer?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let hlsURL = video.hls_url ?? video.playback?.hls_url,
               let url = URL(string: hlsURL) {
                VideoPlayer(player: player)
                    .onAppear {
                        player = AVPlayer(url: url)
                        player?.play()
                    }
                    .onDisappear {
                        player?.pause()
                        player = nil
                    }
            } else if let embedURL = video.embed_url ?? video.playback?.embed_url,
                      let url = URL(string: embedURL) {
                // For embed URLs, show a web view or custom player
                VStack(spacing: 40) {
                    Image(systemName: "play.rectangle")
                        .font(.system(size: 120))
                        .foregroundColor(.blue)
                    
                    Text(video.name)
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    Text("Video Content")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Button("Open in Browser") {
                        if let url = URL(string: embedURL) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.blue)
                    .cornerRadius(8)
                    .buttonStyle(PlainButtonStyle())
                }
            } else {
                VStack(spacing: 30) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.system(size: 100))
                        .foregroundColor(.orange)
                    
                    Text("Video not available")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(video.name)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
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
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(8)
                    .buttonStyle(PlainButtonStyle())
                    
                    Spacer()
                    
                    VStack(alignment: .trailing) {
                        Text(video.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text(video.type.uppercased())
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
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

struct LiveTVPlayerView: View {
    let stream: LiveStream
    @State private var player: AVPlayer?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let hlsURL = stream.hls_url ?? stream.playback?.hls_url,
               let url = URL(string: hlsURL) {
                VideoPlayer(player: player)
                    .onAppear {
                        player = AVPlayer(url: url)
                        player?.play()
                    }
                    .onDisappear {
                        player?.pause()
                        player = nil
                    }
            } else if let embedURL = stream.embed_url ?? stream.playback?.embed_url,
                      let url = URL(string: embedURL) {
                // Show embedded player interface
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
                    
                    Button("Open Stream") {
                        if let url = URL(string: embedURL) {
                            UIApplication.shared.open(url)
                        }
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 30)
                    .padding(.vertical, 15)
                    .background(Color.red)
                    .cornerRadius(8)
                    .buttonStyle(PlainButtonStyle())
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
                                Text(stream.name)
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
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
                    
                    VStack(alignment: .trailing) {
                        Text(stream.name)
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                        
                        if let status = stream.broadcasting_status {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(status == "online" ? Color.green : Color.red)
                                    .frame(width: 8, height: 8)
                                
                                Text(status.uppercased())
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.white)
                            }
                        }
                    }
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
