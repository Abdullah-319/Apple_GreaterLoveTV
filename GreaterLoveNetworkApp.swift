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

// Updated Video model to match API response
struct Video: Codable, Identifiable {
    let id = UUID()
    let _id: String
    let name: String
    let enabled: Bool
    let type: String
    let creation_time: String
    let data: [VideoData]
    let user: String
    
    enum CodingKeys: String, CodingKey {
        case _id, name, enabled, type, creation_time, data, user
    }
}

struct VideoData: Codable, Identifiable {
    let id = UUID()
    let dataId: String
    let fileName: String
    let enabled: Bool
    let bytes: Int
    let mediaInfo: MediaInfo?
    let encodingRequired: Bool
    let precedence: Int
    let author: String
    let creationTime: String
    let _id: String
    let playback: VideoPlayback?
    
    enum CodingKeys: String, CodingKey {
        case dataId = "id", fileName, enabled, bytes, mediaInfo, encodingRequired, precedence, author, creationTime, _id, playback
    }
}

struct MediaInfo: Codable {
    let hasAudioTrack: Bool
    let isVbr: Bool
    let duration: Int
    let width: Int
    let height: Int
    let fps: Int?
    let codecs: [Codec]
    let durationMins: Int
}

struct Codec: Codable {
    let type: String
    let codec: String
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
    let videos: [VideoData]
}

// Updated API Response model
struct VideosResponse: Codable {
    let total: Int
    let page: Int
    let pages: Int
    let docs: [Video]
}

// MARK: - API Service
class CastrAPIService: ObservableObject {
    private let baseURL = "https://api.castr.com/v2"
    private let accessToken = "5aLoKjrNjly4"  // Username
    private let secretKey = "UjTCq8wOj76vjXznGFzdbMRzAkFq6VlJElBQ"  // Password
    
    @Published var liveStreams: [LiveStream] = []
    @Published var videos: [Video] = []
    @Published var videoData: [VideoData] = []
    @Published var categories: [Category] = []
    @Published var recordings: [Recording] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var videoThumbnails: [String: UIImage] = [:]
    
    private var authHeader: String {
        let credentials = "\(accessToken):\(secretKey)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        return "Basic \(base64Credentials)"
    }
    
    func fetchAllContent() {
        testAuthentication()
        addStaticLiveStreams()
        fetchVideos()
        fetchLiveStreams()
    }
    
    // Add static live streams for Greater Love channels
    private func addStaticLiveStreams() {
        let channel1 = LiveStream(
            _id: "static_channel_1",
            name: "Greater Love TV Channel 1",
            enabled: true,
            creation_time: "2025-01-01T00:00:00.000Z",
            embed_url: "https://swf.tulix.tv/iframe/greaterlove/",
            hls_url: "https://rpn.bozztv.com/dvrfl03/itv04060/index.m3u8",
            thumbnail_url: nil,
            broadcasting_status: "online",
            ingest: nil,
            playback: Playback(
                hls_url: "https://rpn.bozztv.com/dvrfl03/itv04060/index.m3u8",
                embed_url: "https://swf.tulix.tv/iframe/greaterlove/",
                embed_audio_url: nil
            )
        )
        
        let channel2 = LiveStream(
            _id: "static_channel_2",
            name: "Greater Love TV Channel 2",
            enabled: true,
            creation_time: "2025-01-01T00:00:00.000Z",
            embed_url: "https://swf.tulix.tv/iframe/greaterlove2/",
            hls_url: "https://rpn.bozztv.com/dvrfl04/itv04019/index.m3u8",
            thumbnail_url: nil,
            broadcasting_status: "online",
            ingest: nil,
            playback: Playback(
                hls_url: "https://rpn.bozztv.com/dvrfl04/itv04019/index.m3u8",
                embed_url: "https://swf.tulix.tv/iframe/greaterlove2/",
                embed_audio_url: nil
            )
        )
        
        DispatchQueue.main.async {
            self.liveStreams = [channel1, channel2]
        }
    }
    
    // Test function to verify authentication
    private func testAuthentication() {
        print("Testing authentication...")
        print("Access Token: \(accessToken)")
        print("Secret Key: \(secretKey)")
        print("Auth Header: \(authHeader)")
        
        // Decode the base64 to verify it's correct
        if let decodedData = Data(base64Encoded: authHeader.replacingOccurrences(of: "Basic ", with: "")),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            print("Decoded credentials: \(decodedString)")
        }
    }
    
    func fetchVideos() {
        isLoading = true
        errorMessage = nil
        
        guard let url = URL(string: "\(baseURL)/videos") else {
            handleError("Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Making request to: \(url)")
        print("Auth header: \(authHeader)")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleError("Network Error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("HTTP Status Code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 401 {
                        self?.handleError("Authentication failed. Please check your API credentials.")
                        return
                    }
                }
                
                guard let data = data else {
                    self?.handleError("No data received")
                    return
                }
                
                // Debug: Print raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("API Response: \(jsonString)")
                }
                
                // Check if response is an error object
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let statusCode = jsonObject["statusCode"] as? Int, statusCode == 401 {
                            self?.handleError("API Authentication Error: \(jsonObject["message"] as? String ?? "Unauthorized")")
                            return
                        }
                    }
                } catch {
                    print("Error parsing JSON object: \(error)")
                }
                
                do {
                    let response = try JSONDecoder().decode(VideosResponse.self, from: data)
                    self?.videos = response.docs.filter { $0.enabled }
                    
                    // Extract all video data for easier access
                    var allVideoData: [VideoData] = []
                    for video in response.docs {
                        allVideoData.append(contentsOf: video.data.filter { $0.enabled })
                    }
                    self?.videoData = allVideoData
                    
                    self?.createCategories(from: allVideoData)
                    self?.isLoading = false
                    
                    print("Successfully loaded \(allVideoData.count) videos")
                    
                    // Generate thumbnails for videos
                    self?.generateThumbnails(for: allVideoData)
                } catch {
                    print("Videos Decoding error: \(error)")
                    self?.handleError("Failed to decode videos: \(error.localizedDescription)")
                    self?.isLoading = false
                }
            }
        }.resume()
    }
    
    func fetchLiveStreams() {
        guard let url = URL(string: "\(baseURL)/live_streams") else {
            handleError("Invalid live streams URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        print("Making live streams request to: \(url)")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleError("Live Streams Network Error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    print("Live Streams HTTP Status Code: \(httpResponse.statusCode)")
                    if httpResponse.statusCode == 401 {
                        self?.handleError("Live Streams Authentication failed.")
                        return
                    }
                }
                
                guard let data = data else {
                    self?.handleError("No live streams data received")
                    return
                }
                
                // Debug: Print raw response
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("Live Streams API Response: \(jsonString)")
                }
                
                // Check if response is an error object
                do {
                    if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                        if let statusCode = jsonObject["statusCode"] as? Int, statusCode == 401 {
                            self?.handleError("Live Streams API Error: \(jsonObject["message"] as? String ?? "Unauthorized")")
                            return
                        }
                    }
                } catch {
                    print("Error parsing live streams JSON object: \(error)")
                }
                
                do {
                    // Try to decode as array first
                    let streams = try JSONDecoder().decode([LiveStream].self, from: data)
                    self?.liveStreams = streams.filter { $0.enabled }
                    print("Successfully loaded \(streams.count) live streams")
                } catch {
                    print("Live Streams Decoding error: \(error)")
                    // Try to parse as object with data array
                    do {
                        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let dataArray = jsonObject["data"] as? [[String: Any]] {
                                let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                                let streams = try JSONDecoder().decode([LiveStream].self, from: jsonData)
                                self?.liveStreams = streams.filter { $0.enabled }
                                print("Successfully loaded \(streams.count) live streams from data array")
                            } else if let docsArray = jsonObject["docs"] as? [[String: Any]] {
                                let jsonData = try JSONSerialization.data(withJSONObject: docsArray)
                                let streams = try JSONDecoder().decode([LiveStream].self, from: jsonData)
                                self?.liveStreams = streams.filter { $0.enabled }
                                print("Successfully loaded \(streams.count) live streams from docs array")
                            } else {
                                self?.handleError("Failed to decode live streams: Unknown structure")
                            }
                        } else {
                            self?.handleError("Failed to decode live streams: Invalid JSON")
                        }
                    } catch {
                        self?.handleError("Live Streams Parsing error: \(error.localizedDescription)")
                    }
                }
            }
        }.resume()
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
    
    private func createCategories(from videoData: [VideoData]) {
        let allVideos = videoData
        
        categories = [
            Category(name: "All", image: "ministry_now", color: .blue, videos: allVideos),
            Category(name: "Original", image: "joni", color: .purple, videos: allVideos.filter { $0.fileName.lowercased().contains("original") }),
            Category(name: "Live TV", image: "rebecca", color: .red, videos: allVideos.filter { $0.fileName.lowercased().contains("live") }),
            Category(name: "Sermons", image: "healing", color: .green, videos: allVideos.filter { $0.fileName.lowercased().contains("sermon") || $0.fileName.lowercased().contains(".mp4") }),
            Category(name: "Shows", image: "marcus", color: .orange, videos: allVideos.filter { $0.fileName.lowercased().contains("show") || $0.fileName.lowercased().contains("tv") })
        ]
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        isLoading = false
        print("Error: \(message)")
    }
    
    // Extract MP4 URL from embed URL with improved parsing
    func extractMP4URL(from embedURL: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: embedURL) else {
            completion(nil)
            return
        }
        
        print("Fetching embed page: \(embedURL)")
        
        // Fetch the embed page and parse for video sources
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                print("Failed to fetch embed page")
                completion(nil)
                return
            }
            
            print("Successfully fetched embed page, searching for video URL...")
            
            // Look for the actual video URL patterns in Castr embed pages
            let patterns = [
                // Look for HLS streams (.m3u8)
                #"https://cstr-vod\.castr\.com/videos/[^/]+/[^/]+\.mp4/index\.m3u8"#,
                #"https://[^"'\s]*\.m3u8[^"'\s]*"#,
                // Look for direct MP4 files
                #"https://cstr-vod\.castr\.com/videos/[^/]+/[^"'\s]*\.mp4"#,
                #"https://player\.castr\.io/[^"'\s]*\.mp4"#,
                // Generic patterns
                #"src\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#,
                #"file\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#,
                #"url\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#,
                #"source\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#
            ]
            
            for (index, pattern) in patterns.enumerated() {
                let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: htmlString.count)
                
                if let match = regex?.firstMatch(in: htmlString, options: [], range: range) {
                    var extractedURL: String
                    
                    if match.numberOfRanges > 1 {
                        // Extract from capture group
                        let urlRange = Range(match.range(at: 1), in: htmlString)!
                        extractedURL = String(htmlString[urlRange])
                    } else {
                        // Extract full match
                        let urlRange = Range(match.range, in: htmlString)!
                        extractedURL = String(htmlString[urlRange]).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    }
                    
                    print("Found video URL with pattern \(index): \(extractedURL)")
                    completion(extractedURL)
                    return
                }
            }
            
            // If no direct video URL found, try to construct one from the video ID
            if embedURL.contains("player.castr.com/vod/") {
                let components = embedURL.components(separatedBy: "/")
                if let videoId = components.last {
                    // Try different URL constructions
                    let possibleURLs = [
                        "https://cstr-vod.castr.com/videos/\(videoId)/index.m3u8",
                        "https://player.castr.io/\(videoId).mp4"
                    ]
                    
                    for testURL in possibleURLs {
                        print("Trying constructed URL: \(testURL)")
                        completion(testURL)
                        return
                    }
                }
            }
            
            print("No video URL found in embed page")
            completion(nil)
        }.resume()
    }
    
    // Generate thumbnail with better error handling and proper URL extraction
    func generateThumbnail(for videoData: VideoData) {
        guard let embedURL = videoData.playback?.embed_url else { return }
        
        extractMP4URL(from: embedURL) { [weak self] extractedURL in
            guard let extractedURL = extractedURL else {
                print("Failed to extract video URL for \(videoData.fileName)")
                DispatchQueue.main.async {
                    self?.createPlaceholderThumbnail(for: videoData)
                }
                return
            }
            
            print("Attempting to generate thumbnail from: \(extractedURL)")
            
            // For HLS streams, try to get a frame, for MP4s use direct approach
            if extractedURL.contains(".m3u8") {
                self?.generateThumbnailFromHLS(extractedURL, for: videoData)
            } else {
                self?.generateThumbnailFromMP4(extractedURL, for: videoData)
            }
        }
    }
    
    // Generate thumbnail from HLS stream
    private func generateThumbnailFromHLS(_ hlsURL: String, for videoData: VideoData) {
        guard let url = URL(string: hlsURL) else {
            DispatchQueue.main.async {
                self.createPlaceholderThumbnail(for: videoData)
            }
            return
        }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 300, height: 170)
        
        let time = CMTime(seconds: 10.0, preferredTimescale: 600) // Try 10 seconds in
        
        DispatchQueue.global(qos: .background).async {
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] (requestedTime, cgImage, actualTime, result, error) in
                
                if let cgImage = cgImage {
                    let thumbnail = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        self?.videoThumbnails[videoData._id] = thumbnail
                        print("Successfully generated thumbnail from HLS for \(videoData.fileName)")
                    }
                } else {
                    print("Failed to generate thumbnail from HLS for \(videoData.fileName): \(error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async {
                        self?.createPlaceholderThumbnail(for: videoData)
                    }
                }
            }
        }
    }
    
    // Generate thumbnail from MP4
    private func generateThumbnailFromMP4(_ mp4URL: String, for videoData: VideoData) {
        guard let url = URL(string: mp4URL) else {
            DispatchQueue.main.async {
                self.createPlaceholderThumbnail(for: videoData)
            }
            return
        }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 300, height: 170)
        
        let time = CMTime(seconds: 5.0, preferredTimescale: 600)
        
        DispatchQueue.global(qos: .background).async {
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] (requestedTime, cgImage, actualTime, result, error) in
                
                if let cgImage = cgImage {
                    let thumbnail = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        self?.videoThumbnails[videoData._id] = thumbnail
                        print("Successfully generated thumbnail from MP4 for \(videoData.fileName)")
                    }
                } else {
                    print("Failed to generate thumbnail from MP4 for \(videoData.fileName): \(error?.localizedDescription ?? "Unknown error")")
                    DispatchQueue.main.async {
                        self?.createPlaceholderThumbnail(for: videoData)
                    }
                }
            }
        }
    }
    
    // Create a placeholder thumbnail with video info
    private func createPlaceholderThumbnail(for videoData: VideoData) {
        let size = CGSize(width: 300, height: 170)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        
        // Create gradient background
        let context = UIGraphicsGetCurrentContext()!
        let colors = [UIColor.systemBlue.cgColor, UIColor.systemPurple.cgColor]
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: nil)!
        context.drawLinearGradient(gradient, start: CGPoint.zero, end: CGPoint(x: size.width, y: size.height), options: [])
        
        // Add play icon
        let playIcon = UIImage(systemName: "play.circle.fill")?.withTintColor(.white, renderingMode: .alwaysOriginal)
        let iconSize: CGFloat = 40
        let iconRect = CGRect(x: (size.width - iconSize) / 2, y: (size.height - iconSize) / 2, width: iconSize, height: iconSize)
        playIcon?.draw(in: iconRect)
        
        // Add duration if available
        if let duration = videoData.mediaInfo?.durationMins {
            let durationText = "\(duration) min"
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 12, weight: .medium),
                .foregroundColor: UIColor.white
            ]
            let textSize = durationText.size(withAttributes: attributes)
            let textRect = CGRect(x: size.width - textSize.width - 8, y: size.height - textSize.height - 8, width: textSize.width, height: textSize.height)
            durationText.draw(in: textRect, withAttributes: attributes)
        }
        
        let placeholderImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        if let placeholder = placeholderImage {
            videoThumbnails[videoData._id] = placeholder
        }
    }
    
    // Generate thumbnails for multiple videos with better approach
    private func generateThumbnails(for videoDataArray: [VideoData]) {
        // Generate placeholder thumbnails immediately for better UX
        for videoData in videoDataArray {
            createPlaceholderThumbnail(for: videoData)
        }
        
        // Then try to generate real thumbnails for first few videos
        for videoData in videoDataArray.prefix(5) {
            DispatchQueue.global(qos: .background).asyncAfter(deadline: .now() + Double.random(in: 0...2)) {
                self.generateThumbnail(for: videoData)
            }
        }
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
            // Updated Logo with proper image
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    // Logo Image
                    Image("tvos_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    VStack(alignment: .leading, spacing: 2) {
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
                }
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
            } else if let videoData = selectedContent as? VideoData {
                VideoDataPlayerView(videoData: videoData)
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
                    if apiService.isLoading || apiService.videoData.isEmpty {
                        // Show loading placeholders
                        ForEach(0..<5, id: \.self) { _ in
                            LoadingCard()
                        }
                    } else {
                        ForEach(Array(apiService.videoData.prefix(5))) { videoData in
                            VideoDataCard(videoData: videoData) {
                                selectedContent = videoData
                                showingVideoPlayer = true
                            }
                            .environmentObject(apiService)
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
                    if apiService.isLoading || apiService.videoData.isEmpty {
                        // Show loading placeholders
                        ForEach(0..<6, id: \.self) { index in
                            LoadingShowCard(color: [Color.blue, Color.purple, Color.green, Color.orange, Color.red, Color.cyan][index])
                        }
                    } else {
                        ForEach(Array(apiService.videoData.prefix(6).enumerated()), id: \.element.id) { index, videoData in
                            let colors: [Color] = [.blue, .purple, .green, .orange, .red, .cyan]
                            ShowCircleCard(
                                videoData: videoData,
                                color: colors[index % colors.count]
                            ) {
                                selectedContent = videoData
                                showingVideoPlayer = true
                            }
                            .environmentObject(apiService)
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
struct VideoDataCard: View {
    let videoData: VideoData
    let action: () -> Void
    @EnvironmentObject var apiService: CastrAPIService
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                // Display thumbnail if available, otherwise show gradient placeholder
                Group {
                    if let thumbnail = apiService.videoThumbnails[videoData._id] {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 300, height: 170)
                            .clipped()
                    } else {
                        Rectangle()
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.blue.opacity(0.7),
                                        Color.purple.opacity(0.5)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 300, height: 170)
                            .overlay(
                                VStack(spacing: 10) {
                                    Image(systemName: "play.circle.fill")
                                        .font(.system(size: 40))
                                        .foregroundColor(.white)
                                    
                                    if let duration = videoData.mediaInfo?.durationMins {
                                        Text("\(duration) min")
                                            .font(.system(size: 12, weight: .medium))
                                            .foregroundColor(.white.opacity(0.8))
                                    }
                                }
                            )
                    }
                }
                .cornerRadius(12)
                .overlay(
                    // Play button overlay
                    VStack {
                        Spacer()
                        HStack {
                            Spacer()
                            Image(systemName: "play.circle.fill")
                                .font(.system(size: 30))
                                .foregroundColor(.white)
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                                .padding(8)
                        }
                    }
                )
                
                Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Generate thumbnail if not already available
            if apiService.videoThumbnails[videoData._id] == nil {
                apiService.generateThumbnail(for: videoData)
            }
        }
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
    let videoData: VideoData
    let color: Color
    let action: () -> Void
    @EnvironmentObject var apiService: CastrAPIService
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                // Circular show image with thumbnail or gradient
                Group {
                    if let thumbnail = apiService.videoThumbnails[videoData._id] {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                            .overlay(
                                Circle()
                                    .stroke(Color.white, lineWidth: 3)
                            )
                    } else {
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
                                Text(String(videoData.fileName.prefix(2).uppercased()))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                
                VStack(spacing: 8) {
                    Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .lineLimit(2)
                        .frame(width: 140)
                    
                    if let duration = videoData.mediaInfo?.durationMins {
                        Text("\(duration) min")
                            .font(.system(size: 12, weight: .regular))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .frame(width: 140)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .onAppear {
            // Generate thumbnail if not already available
            if apiService.videoThumbnails[videoData._id] == nil {
                apiService.generateThumbnail(for: videoData)
            }
        }
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
struct VideoDataPlayerView: View {
    let videoData: VideoData
    @State private var player: AVPlayer?
    @State private var mp4URL: String?
    @State private var isLoadingVideo = true
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if isLoadingVideo {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(2)
                    
                    Text("Loading video...")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                    
                    Text(videoData.fileName)
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
            } else if let mp4URL = mp4URL, let url = URL(string: mp4URL) {
                // Play the video directly (supports both MP4 and HLS)
                VideoPlayer(player: player)
                    .onAppear {
                        print("Starting video playback: \(mp4URL)")
                        player = AVPlayer(url: url)
                        player?.play()
                    }
                    .onDisappear {
                        print("Stopping video playback")
                        player?.pause()
                        player = nil
                    }
                    .overlay(
                        // Add loading overlay for video buffering
                        Group {
                            if player?.currentItem?.status == .unknown {
                                VStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                        .scaleEffect(1.5)
                                    
                                    Text("Buffering...")
                                        .font(.system(size: 16, weight: .medium))
                                        .foregroundColor(.white)
                                        .padding(.top, 10)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                                .background(Color.black.opacity(0.7))
                            }
                        }
                    )
            } else if let embedURL = videoData.playback?.embed_url,
                      let url = URL(string: embedURL) {
                // Fallback to embed player
                VStack(spacing: 40) {
                    Image(systemName: "play.rectangle.fill")
                        .font(.system(size: 120))
                        .foregroundColor(.blue)
                    
                    Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    if let duration = videoData.mediaInfo?.durationMins {
                        Text("Duration: \(duration) minutes")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    
                    VStack(spacing: 20) {
                        Text("Video Content")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.gray)
                        
                        Button("Open in Browser") {
                            UIApplication.shared.open(url)
                        }
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 30)
                        .padding(.vertical, 15)
                        .background(Color.blue)
                        .cornerRadius(8)
                        .buttonStyle(PlainButtonStyle())
                        
                        Button("Play Embedded") {
                            UIApplication.shared.open(url)
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 25)
                        .padding(.vertical, 12)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            } else {
                VStack(spacing: 40) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 100))
                        .foregroundColor(.orange)
                    
                    Text("Video not available")
                        .font(.system(size: 24, weight: .medium))
                        .foregroundColor(.gray)
                    
                    Text(videoData.fileName)
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                    
                    Text("The video content is currently unavailable or the embed URL is missing.")
                        .font(.system(size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 60)
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
                        Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.white)
                            .lineLimit(1)
                        
                        if let duration = videoData.mediaInfo?.durationMins {
                            Text("\(duration) min")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
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
        .onAppear {
            loadVideoURL()
        }
    }
    
    private func loadVideoURL() {
        guard let embedURL = videoData.playback?.embed_url else {
            isLoadingVideo = false
            return
        }
        
        print("Loading video URL for: \(videoData.fileName)")
        print("Embed URL: \(embedURL)")
        
        // Extract video URL from embed page
        extractVideoURLFromEmbed(embedURL)
    }
    
    private func extractVideoURLFromEmbed(_ embedURL: String) {
        guard let url = URL(string: embedURL) else {
            isLoadingVideo = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { [self] data, response, error in
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.isLoadingVideo = false
                }
                return
            }
            
            print("Fetched embed page, searching for video URL...")
            
            // Look for video URLs in the HTML content
            let patterns = [
                // Look for HLS streams (.m3u8) - preferred for iOS
                #"https://cstr-vod\.castr\.com/videos/[^/]+/[^/]+\.mp4/index\.m3u8"#,
                #"https://[^"'\s]*\.m3u8[^"'\s]*"#,
                // Look for direct MP4 files
                #"https://cstr-vod\.castr\.com/videos/[^/]+/[^"'\s]*\.mp4"#,
                #"https://player\.castr\.io/[^"'\s]*\.mp4"#,
                // Generic patterns with capture groups
                #"src\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#,
                #"file\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#,
                #"url\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#,
                #"source\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#
            ]
            
            for (index, pattern) in patterns.enumerated() {
                let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: htmlString.count)
                
                if let match = regex?.firstMatch(in: htmlString, options: [], range: range) {
                    var extractedURL: String
                    
                    if match.numberOfRanges > 1 {
                        // Extract from capture group
                        let urlRange = Range(match.range(at: 1), in: htmlString)!
                        extractedURL = String(htmlString[urlRange])
                    } else {
                        // Extract full match
                        let urlRange = Range(match.range, in: htmlString)!
                        extractedURL = String(htmlString[urlRange]).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    }
                    
                    print("Found potential video URL with pattern \(index): \(extractedURL)")
                    
                    // Test if this URL works
                    self.testVideoURL(extractedURL) { works in
                        DispatchQueue.main.async {
                            if works {
                                self.mp4URL = extractedURL
                                print("Video URL works: \(extractedURL)")
                            }
                            self.isLoadingVideo = false
                        }
                    }
                    return
                }
            }
            
            // If no video URL found, try to construct one from the video ID
            if embedURL.contains("player.castr.com/vod/") {
                let components = embedURL.components(separatedBy: "/")
                if let videoId = components.last {
                    // Try different URL constructions based on the pattern you provided
                    let possibleURLs = [
                        "https://cstr-vod.castr.com/videos/\(videoId)/index.m3u8",
                        "https://player.castr.io/\(videoId).mp4"
                    ]
                    
                    for testURL in possibleURLs {
                        print("Trying constructed URL: \(testURL)")
                        self.testVideoURL(testURL) { works in
                            DispatchQueue.main.async {
                                if works {
                                    self.mp4URL = testURL
                                    print("Constructed video URL works: \(testURL)")
                                    self.isLoadingVideo = false
                                    return
                                }
                            }
                        }
                    }
                }
            }
            
            print("No working video URL found")
            DispatchQueue.main.async {
                self.isLoadingVideo = false
            }
        }.resume()
    }
    
    private func testVideoURL(_ urlString: String, completion: @escaping (Bool) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false)
            return
        }
        
        print("Testing video URL: \(urlString)")
        
        // For HLS streams, test differently than MP4 files
        if urlString.contains(".m3u8") {
            // For HLS, just check if we can create an AVPlayerItem
            let playerItem = AVPlayerItem(url: url)
            
            // Test if the item loads successfully
            let testPlayer = AVPlayer(playerItem: playerItem)
            
            // Use a simple timeout-based test
            DispatchQueue.global().asyncAfter(deadline: .now() + 2) {
                let status = playerItem.status
                let isPlayable = status == .readyToPlay || status == .unknown
                print("HLS URL test result for \(urlString): \(isPlayable ? "SUCCESS" : "FAILED") (status: \(status.rawValue))")
                completion(isPlayable)
            }
        } else {
            // For MP4 files, test HTTP HEAD request
            var request = URLRequest(url: url)
            request.httpMethod = "HEAD"
            request.timeoutInterval = 5
            
            URLSession.shared.dataTask(with: request) { _, response, error in
                guard let httpResponse = response as? HTTPURLResponse else {
                    print("MP4 URL test failed for \(urlString): No HTTP response")
                    completion(false)
                    return
                }
                
                let isValid = httpResponse.statusCode == 200
                print("MP4 URL test result for \(urlString): \(isValid ? "SUCCESS" : "FAILED") (status: \(httpResponse.statusCode))")
                completion(isValid)
            }.resume()
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
                        UIApplication.shared.open(url)
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
