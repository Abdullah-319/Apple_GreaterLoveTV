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

// MARK: - Thumbnail Loading State
enum ThumbnailState: Equatable {
    case loading
    case loaded(UIImage)
    case failed
    
    static func == (lhs: ThumbnailState, rhs: ThumbnailState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading), (.failed, .failed):
            return true
        case (.loaded(let lhsImage), (.loaded(let rhsImage))):
            return lhsImage.pngData() == rhsImage.pngData()
        default:
            return false
        }
    }
}

// MARK: - API Service
class CastrAPIService: ObservableObject {
    private let baseURL = "https://api.castr.com/v2"
    private let accessToken = "5aLoKjrNjly4"
    private let secretKey = "UjTCq8wOj76vjXznGFzdbMRzAkFq6VlJElBQ"
    
    @Published var liveStreams: [LiveStream] = []
    @Published var videos: [Video] = []
    @Published var videoData: [VideoData] = []
    @Published var categories: [Category] = []
    @Published var recordings: [Recording] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var thumbnailStates: [String: ThumbnailState] = [:]
    
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
    
    private func testAuthentication() {
        print("Testing authentication...")
        print("Access Token: \(accessToken)")
        print("Secret Key: \(secretKey)")
        print("Auth Header: \(authHeader)")
        
        if let decodedData = Data(base64Encoded: authHeader.replacingOccurrences(of: "Basic ", with: "")),
           let decodedString = String(data: decodedData, encoding: .utf8) {
            print("Decoded credentials: \(decodedString)")
        }
    }
    
    // In CastrAPIService.swift
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
                
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("API Response: \(jsonString.prefix(500))...")
                }
                
                do {
                    let response = try JSONDecoder().decode(VideosResponse.self, from: data)
                    self?.videos = response.docs.filter { $0.enabled }
                    
                    // Collect ALL video data from ALL enabled docs
                    var allVideoData: [VideoData] = []
                    for video in response.docs where video.enabled {
                        allVideoData.append(contentsOf: video.data)
                    }
                    
                    // Filter out disabled videos
                    let enabledVideoData = allVideoData.filter { $0.enabled }
                    self?.videoData = enabledVideoData
                    self?.createCategories(from: enabledVideoData)
                    self?.isLoading = false
                    
                    print("Successfully loaded \(enabledVideoData.count) videos from \(response.docs.count) documents")
                    
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
                
                do {
                    let streams = try JSONDecoder().decode([LiveStream].self, from: data)
                    // Don't replace, append to existing static streams
                    let apiStreams = streams.filter { $0.enabled }
                    self?.liveStreams.append(contentsOf: apiStreams)
                    print("Successfully loaded \(apiStreams.count) API live streams")
                } catch {
                    print("Live Streams Decoding error: \(error)")
                    do {
                        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let dataArray = jsonObject["data"] as? [[String: Any]] {
                                let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                                let streams = try JSONDecoder().decode([LiveStream].self, from: jsonData)
                                let apiStreams = streams.filter { $0.enabled }
                                self?.liveStreams.append(contentsOf: apiStreams)
                                print("Successfully loaded \(apiStreams.count) API live streams from data array")
                            }
                        }
                    } catch {
                        self?.handleError("Live Streams Parsing error: \(error.localizedDescription)")
                    }
                }
            }
        }.resume()
    }
    
    private func createCategories(from videoData: [VideoData]) {
        let allVideos = videoData
        
        categories = [
            Category(name: "All", image: "ministry_now", color: .blue, videos: allVideos),
            Category(name: "Recent", image: "joni", color: .purple, videos: Array(allVideos.sorted(by: { $0.creationTime > $1.creationTime }).prefix(20))),
            Category(name: "Live TV", image: "rebecca", color: .red, videos: allVideos.filter { $0.fileName.lowercased().contains("live") }),
            Category(name: "Sermons", image: "healing", color: .green, videos: allVideos.filter { $0.fileName.lowercased().contains("sermon") || $0.fileName.lowercased().contains("truth") || $0.fileName.lowercased().contains("daniel") || $0.fileName.lowercased().contains("acts") }),
            Category(name: "Shows", image: "marcus", color: .orange, videos: allVideos.filter { $0.fileName.lowercased().contains("show") || $0.fileName.lowercased().contains("voice") || $0.fileName.lowercased().contains("awaken") })
        ]
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        isLoading = false
        print("Error: \(message)")
    }
    
    private func initializeThumbnailStates(for videoDataArray: [VideoData]) {
        for videoData in videoDataArray {
            thumbnailStates[videoData._id] = .loading
        }
        
        for videoData in videoDataArray.prefix(10) {
            loadThumbnail(for: videoData)
        }
    }
    
    func loadThumbnail(for videoData: VideoData) {
        guard thumbnailStates[videoData._id] == .loading else { return }
        
        guard let embedURL = videoData.playback?.embed_url else {
            DispatchQueue.main.async {
                self.thumbnailStates[videoData._id] = .failed
            }
            return
        }
        
        extractMP4URL(from: embedURL) { [weak self] extractedURL in
            guard let extractedURL = extractedURL else {
                DispatchQueue.main.async {
                    self?.thumbnailStates[videoData._id] = .failed
                }
                return
            }
            
            if extractedURL.contains(".m3u8") {
                self?.generateThumbnailFromHLS(extractedURL, for: videoData)
            } else {
                self?.generateThumbnailFromMP4(extractedURL, for: videoData)
            }
        }
    }
    
    func extractMP4URL(from embedURL: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: embedURL) else {
            completion(nil)
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            
            let patterns = [
                #"https://cstr-vod\.castr\.com/videos/[^/]+/[^/]+\.mp4/index\.m3u8"#,
                #"https://[^"'\s]*\.m3u8[^"'\s]*"#,
                #"https://cstr-vod\.castr\.com/videos/[^/]+/[^"'\s]*\.mp4"#,
                #"src\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#,
                #"file\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#
            ]
            
            for pattern in patterns {
                let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: htmlString.count)
                
                if let match = regex?.firstMatch(in: htmlString, options: [], range: range) {
                    var extractedURL: String
                    
                    if match.numberOfRanges > 1 {
                        let urlRange = Range(match.range(at: 1), in: htmlString)!
                        extractedURL = String(htmlString[urlRange])
                    } else {
                        let urlRange = Range(match.range, in: htmlString)!
                        extractedURL = String(htmlString[urlRange]).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    }
                    
                    completion(extractedURL)
                    return
                }
            }
            
            if embedURL.contains("player.castr.com/vod/") {
                let components = embedURL.components(separatedBy: "/")
                if let videoId = components.last {
                    let possibleURLs = [
                        "https://cstr-vod.castr.com/videos/\(videoId)/index.m3u8",
                        "https://player.castr.io/\(videoId).mp4"
                    ]
                    
                    for testURL in possibleURLs {
                        completion(testURL)
                        return
                    }
                }
            }
            
            completion(nil)
        }.resume()
    }
    
    private func generateThumbnailFromHLS(_ hlsURL: String, for videoData: VideoData) {
        guard let url = URL(string: hlsURL) else {
            DispatchQueue.main.async {
                self.thumbnailStates[videoData._id] = .failed
            }
            return
        }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 300, height: 170)
        
        let time = CMTime(seconds: 10.0, preferredTimescale: 600)
        
        DispatchQueue.global(qos: .background).async {
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] (_, cgImage, _, _, _) in
                if let cgImage = cgImage {
                    let thumbnail = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        self?.thumbnailStates[videoData._id] = .loaded(thumbnail)
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.thumbnailStates[videoData._id] = .failed
                    }
                }
            }
        }
    }
    
    private func generateThumbnailFromMP4(_ mp4URL: String, for videoData: VideoData) {
        guard let url = URL(string: mp4URL) else {
            DispatchQueue.main.async {
                self.thumbnailStates[videoData._id] = .failed
            }
            return
        }
        
        let asset = AVAsset(url: url)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        imageGenerator.appliesPreferredTrackTransform = true
        imageGenerator.maximumSize = CGSize(width: 300, height: 170)
        
        let time = CMTime(seconds: 5.0, preferredTimescale: 600)
        
        DispatchQueue.global(qos: .background).async {
            imageGenerator.generateCGImagesAsynchronously(forTimes: [NSValue(time: time)]) { [weak self] (_, cgImage, _, _, _) in
                if let cgImage = cgImage {
                    let thumbnail = UIImage(cgImage: cgImage)
                    DispatchQueue.main.async {
                        self?.thumbnailStates[videoData._id] = .loaded(thumbnail)
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.thumbnailStates[videoData._id] = .failed
                    }
                }
            }
        }
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

// MARK: - Enhanced Video Player with Custom Controls
struct VideoDataPlayerView: View {
    let videoData: VideoData
    @State private var player: AVPlayer?
    @State private var mp4URL: String?
    @State private var isLoadingVideo = true
    @State private var isBuffering = false
    @State private var playerTimeObserver: Any?
    @State private var currentTime: Double = 0
    @State private var duration: Double = 0
    @State private var isPlaying = false
    @State private var showControls = true
    @State private var controlsTimer: Timer?
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
                // Custom Video Player with Controls
                ZStack {
                    VideoPlayer(player: player)
                        .onTapGesture {
                            toggleControlsVisibility()
                        }
                        .onAppear {
                            setupPlayer(with: url)
                        }
                        .onDisappear {
                            cleanupPlayer()
                        }
                    
                    // Buffering Overlay
                    if isBuffering {
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
                    
                    // Custom Controls Overlay
                    if showControls {
                        VStack {
                            // Top Controls
                            HStack {
                                CTAButton(title: "Back") {
                                    presentationMode.wrappedValue.dismiss()
                                }
                                
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
                            .padding(.horizontal, 50)
                            .padding(.top, 50)
                            
                            Spacer()
                            
                            // Bottom Controls
                            VStack(spacing: 20) {
                                // Progress Bar
                                VStack(spacing: 8) {
                                    // Time Labels
                                    HStack {
                                        Text(formatTime(currentTime))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        Text(formatTime(duration))
                                            .font(.system(size: 14, weight: .medium))
                                            .foregroundColor(.white)
                                    }
                                    
                                    // Progress Slider
                                    ProgressSlider(
                                        value: $currentTime,
                                        maxValue: duration,
                                        onEditingChanged: { editing in
                                            if !editing {
                                                seekToTime(currentTime)
                                            }
                                        }
                                    )
                                }
                                
                                // Control Buttons
                                HStack(spacing: 60) {
                                    // Backward 10s
                                    VideoControlButton(
                                        systemName: "gobackward.10",
                                        action: { seekBackward() }
                                    )
                                    
                                    // Play/Pause
                                    VideoControlButton(
                                        systemName: isPlaying ? "pause.fill" : "play.fill",
                                        size: 60,
                                        action: { togglePlayPause() }
                                    )
                                    
                                    // Forward 10s
                                    VideoControlButton(
                                        systemName: "goforward.10",
                                        action: { seekForward() }
                                    )
                                }
                            }
                            .padding(.horizontal, 50)
                            .padding(.bottom, 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.clear, Color.black.opacity(0.8)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                        }
                        .transition(.opacity)
                    }
                }
            } else {
                // Fallback view
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
        }
        .onAppear {
            loadVideoURL()
            startControlsTimer()
        }
        .onDisappear {
            controlsTimer?.invalidate()
        }
    }
    
    private func setupPlayer(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        // Setup buffering observation
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { _ in
            isBuffering = true
        }
        
        // Setup time observation
        playerTimeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { time in
            DispatchQueue.main.async {
                guard let player = self.player else { return }
                
                self.currentTime = time.seconds
                if let duration = player.currentItem?.duration.seconds, !duration.isNaN {
                    self.duration = duration
                }
                
                // Update playing state
                self.isPlaying = player.rate > 0
                
                // Update buffering state
                if let item = player.currentItem {
                    if item.status == .readyToPlay && item.isPlaybackLikelyToKeepUp {
                        self.isBuffering = false
                    } else if item.status == .readyToPlay && !item.isPlaybackLikelyToKeepUp {
                        self.isBuffering = true
                    }
                }
            }
        }
        
        player?.play()
    }
    
    private func cleanupPlayer() {
        player?.pause()
        controlsTimer?.invalidate()
        
        NotificationCenter.default.removeObserver(self)
        
        if let timeObserver = playerTimeObserver {
            player?.removeTimeObserver(timeObserver)
            playerTimeObserver = nil
        }
        
        player = nil
    }
    
    private func loadVideoURL() {
        guard let embedURL = videoData.playback?.embed_url else {
            isLoadingVideo = false
            return
        }
        
        extractVideoURLFromEmbed(embedURL)
    }
    
    private func extractVideoURLFromEmbed(_ embedURL: String) {
        guard let url = URL(string: embedURL) else {
            isLoadingVideo = false
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                DispatchQueue.main.async {
                    self.isLoadingVideo = false
                }
                return
            }
            
            let patterns = [
                #"https://cstr-vod\.castr\.com/videos/[^/]+/[^/]+\.mp4/index\.m3u8"#,
                #"https://[^"'\s]*\.m3u8[^"'\s]*"#,
                #"https://cstr-vod\.castr\.com/videos/[^/]+/[^"'\s]*\.mp4"#,
                #"src\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#,
                #"file\s*[=:]\s*["']([^"']*\.(mp4|m3u8)[^"']*)"#
            ]
            
            for pattern in patterns {
                let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let range = NSRange(location: 0, length: htmlString.count)
                
                if let match = regex?.firstMatch(in: htmlString, options: [], range: range) {
                    var extractedURL: String
                    
                    if match.numberOfRanges > 1 {
                        let urlRange = Range(match.range(at: 1), in: htmlString)!
                        extractedURL = String(htmlString[urlRange])
                    } else {
                        let urlRange = Range(match.range, in: htmlString)!
                        extractedURL = String(htmlString[urlRange]).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
                    }
                    
                    DispatchQueue.main.async {
                        self.mp4URL = extractedURL
                        self.isLoadingVideo = false
                    }
                    return
                }
            }
            
            if embedURL.contains("player.castr.com/vod/") {
                let components = embedURL.components(separatedBy: "/")
                if let videoId = components.last {
                    let possibleURLs = [
                        "https://cstr-vod.castr.com/videos/\(videoId)/index.m3u8",
                        "https://player.castr.io/\(videoId).mp4"
                    ]
                    
                    for testURL in possibleURLs {
                        DispatchQueue.main.async {
                            self.mp4URL = testURL
                            self.isLoadingVideo = false
                        }
                        return
                    }
                }
            }
            
            DispatchQueue.main.async {
                self.isLoadingVideo = false
            }
        }.resume()
    }
    
    // MARK: - Video Control Functions
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if player.rate > 0 {
            player.pause()
        } else {
            player.play()
        }
        resetControlsTimer()
    }
    
    private func seekForward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeAdd(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player.seek(to: newTime)
        resetControlsTimer()
    }
    
    private func seekBackward() {
        guard let player = player else { return }
        let currentTime = player.currentTime()
        let newTime = CMTimeSubtract(currentTime, CMTime(seconds: 10, preferredTimescale: 1))
        player.seek(to: newTime)
        resetControlsTimer()
    }
    
    private func seekToTime(_ time: Double) {
        guard let player = player else { return }
        let cmTime = CMTime(seconds: time, preferredTimescale: 1)
        player.seek(to: cmTime)
        resetControlsTimer()
    }
    
    private func toggleControlsVisibility() {
        withAnimation(.easeInOut(duration: 0.3)) {
            showControls.toggle()
        }
        if showControls {
            resetControlsTimer()
        }
    }
    
    private func startControlsTimer() {
        controlsTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation(.easeInOut(duration: 0.3)) {
                showControls = false
            }
        }
    }
    
    private func resetControlsTimer() {
        controlsTimer?.invalidate()
        showControls = true
        startControlsTimer()
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds.isFinite else { return "00:00" }
        
        let totalSeconds = Int(seconds)
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
}

// MARK: - Custom Video Control Components
struct VideoControlButton: View {
    let systemName: String
    var size: CGFloat = 50
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: size * 0.6, weight: .medium))
                .foregroundColor(.white)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(Color.black.opacity(0.6))
                )
                .scaleEffect(isFocused ? 1.1 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}

struct ProgressSlider: View {
    @Binding var value: Double
    let maxValue: Double
    let onEditingChanged: (Bool) -> Void
    @FocusState private var isFocused: Bool
    @State private var isEditing = false
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                // Background track
                Rectangle()
                    .fill(Color.white.opacity(0.3))
                    .frame(height: 4)
                    .cornerRadius(2)
                
                // Progress track
                Rectangle()
                    .fill(Color.red)
                    .frame(width: progressWidth(geometry.size.width), height: 4)
                    .cornerRadius(2)
                
                // Thumb
                Circle()
                    .fill(Color.white)
                    .frame(width: isFocused ? 16 : 12, height: isFocused ? 16 : 12)
                    .offset(x: progressWidth(geometry.size.width) - (isFocused ? 8 : 6))
                    .animation(.easeInOut(duration: 0.1), value: isFocused)
            }
        }
        .frame(height: 20)
        .focusable()
        .focused($isFocused)
        .onMoveCommand { direction in
            let step = maxValue / 100
            switch direction {
            case .left:
                value = max(0, value - step)
                onEditingChanged(false)
            case .right:
                value = min(maxValue, value + step)
                onEditingChanged(false)
            default:
                break
            }
        }
    }
    
    private func progressWidth(_ totalWidth: CGFloat) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        return totalWidth * CGFloat(value / maxValue)
    }
}

// MARK: - Live TV Player (Updated without focus colors)
struct LiveTVPlayerView: View {
    let stream: LiveStream
    @State private var player: AVPlayer?
    @State private var isBuffering = false
    @State private var playerTimeObserver: Any?
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            if let hlsURL = stream.hls_url ?? stream.playback?.hls_url,
               let url = URL(string: hlsURL) {
                VideoPlayer(player: player)
                    .onAppear {
                        setupPlayer(with: url)
                    }
                    .onDisappear {
                        cleanupPlayer()
                    }
                    .overlay(
                        Group {
                            if isBuffering {
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
            } else {
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
                }
            }
            
            // Controls Overlay
            VStack {
                HStack {
                    CTAButton(title: "Back") {
                        presentationMode.wrappedValue.dismiss()
                    }
                    
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
    
    private func setupPlayer(with url: URL) {
        let playerItem = AVPlayerItem(url: url)
        player = AVPlayer(playerItem: playerItem)
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemPlaybackStalled,
            object: playerItem,
            queue: .main
        ) { _ in
            isBuffering = true
        }
        
        playerTimeObserver = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { _ in
            DispatchQueue.main.async {
                guard let item = self.player?.currentItem else { return }
                
                if item.status == .readyToPlay && item.isPlaybackLikelyToKeepUp {
                    self.isBuffering = false
                } else if item.status == .readyToPlay && !item.isPlaybackLikelyToKeepUp {
                    self.isBuffering = true
                }
            }
        }
        
        player?.play()
    }
    
    private func cleanupPlayer() {
        player?.pause()
        
        NotificationCenter.default.removeObserver(self)
        
        if let timeObserver = playerTimeObserver {
            player?.removeTimeObserver(timeObserver)
            playerTimeObserver = nil
        }
        
        player = nil
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

// MARK: - Content View
struct ContentView: View {
    @StateObject private var apiService = CastrAPIService()
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

// MARK: - Navigation Bar (Updated without hover colors)
struct NavigationBar: View {
    @Binding var selectedItem: String
    
    private let navItems = ["HOME", "ABOUT US", "ALL CATEGORIES"]
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 12) {
                    Image("tvos_logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 200, height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding(.leading, 60)
            
            Spacer()
            
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
        .background(Color.black.opacity(0.95))
        .zIndex(1)
    }
}

// MARK: - Navigation Bar Button (Removed hover colors)
struct NavigationBarButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .font(.custom("Poppins-SemiBold", size: 14))
                    .foregroundColor(.white)
                    .kerning(0.5)
                
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
            .scaleEffect(isFocused ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}

// MARK: - Home View
struct HomeView: View {
    @EnvironmentObject var apiService: CastrAPIService
    @State private var selectedContent: Any?
    @State private var showingVideoPlayer = false
    
    var body: some View {
        VStack(spacing: 0) {
            headerSection()
            
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
            Spacer()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 20) {
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
                        
                        CTAButton(title: "Continue Watching") {
                            // Scroll to continue watching section
                        }
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
                        ForEach(0..<5, id: \.self) { _ in
                            LoadingCard()
                        }
                    } else {
                        ForEach(Array(apiService.videoData.prefix(10))) { videoData in
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

// MARK: - CTA Button (Removed hover colors)
struct CTAButton: View {
    let title: String
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.custom("Poppins-SemiBold", size: 18))
                .foregroundColor(.white)
                .padding(.horizontal, 40)
                .padding(.vertical, 18)
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(red: 0.9, green: 0.2, blue: 0.2))
                )
                .scaleEffect(isFocused ? 1.05 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}

// MARK: - About View
struct AboutView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 80) {
            Spacer()
                .frame(height: 40)
            
            VStack(spacing: 100) {
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
                        
                        CTAButton(title: "CONTACT US") {
                            // Action
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Rectangle()
                        .fill(Color.blue.opacity(0.3))
                        .aspectRatio(4/3, contentMode: .fit)
                        .frame(maxWidth: 400)
                        .cornerRadius(12)
                }
                .padding(.horizontal, 80)
                
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
                        
                        CTAButton(title: "DONATE NOW") {
                            // Action
                        }
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
            Spacer()
                .frame(height: 40)
            
            VStack(alignment: .leading, spacing: 60) {
                Text("ALL CATEGORIES")
                    .font(.system(size: 36, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 80)
                
                if apiService.isLoading || apiService.categories.isEmpty {
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

// MARK: - Card Components (Updated without hover colors)
struct VideoDataCard: View {
    let videoData: VideoData
    let action: () -> Void
    @EnvironmentObject var apiService: CastrAPIService
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 15) {
                Group {
                    switch apiService.thumbnailStates[videoData._id] {
                    case .loading:
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 300, height: 170)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(1.2)
                            )
                    case .loaded(let image):
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 300, height: 170)
                            .clipped()
                    case .failed, .none:
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
                .scaleEffect(isFocused ? 1.05 : 1.0)
                
                Text(videoData.fileName.replacingOccurrences(of: ".mp4", with: ""))
                    .font(.custom("Poppins-Medium", size: 16))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
                    .frame(width: 300)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
        .onAppear {
            if apiService.thumbnailStates[videoData._id] == .loading || apiService.thumbnailStates[videoData._id] == nil {
                apiService.loadThumbnail(for: videoData)
            }
        }
    }
}

struct CategoryCard: View {
    let category: Category
    @FocusState private var isFocused: Bool
    
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
                    .scaleEffect(isFocused ? 1.05 : 1.0)
                
                Text(category.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}

struct CategoryDetailCard: View {
    let category: Category
    @FocusState private var isFocused: Bool
    
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
                    .scaleEffect(isFocused ? 1.05 : 1.0)
                
                Text(category.name)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
            }
        }
        .buttonStyle(PlainButtonStyle())
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}

struct ShowCircleCard: View {
    let videoData: VideoData
    let color: Color
    let action: () -> Void
    @EnvironmentObject var apiService: CastrAPIService
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 20) {
                Group {
                    switch apiService.thumbnailStates[videoData._id] {
                    case .loading:
                        Circle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 140, height: 140)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            )
                    case .loaded(let image):
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 140, height: 140)
                            .clipShape(Circle())
                    case .failed, .none:
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
                                Text(String(videoData.fileName.prefix(2).uppercased()))
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(.white)
                            )
                    }
                }
                .scaleEffect(isFocused ? 1.05 : 1.0)
                
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
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
        .onAppear {
            if apiService.thumbnailStates[videoData._id] == .loading || apiService.thumbnailStates[videoData._id] == nil {
                apiService.loadThumbnail(for: videoData)
            }
        }
    }
}

struct LiveStreamCard: View {
    let stream: LiveStream
    let number: String
    let subtitle: String
    let action: () -> Void
    @FocusState private var isFocused: Bool
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 25) {
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
                    .scaleEffect(isFocused ? 1.05 : 1.0)
                
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
        .focused($isFocused)
        .animation(.easeInOut(duration: 0.1), value: isFocused)
    }
}
