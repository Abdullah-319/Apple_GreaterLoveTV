import SwiftUI
import Foundation

// MARK: - Enhanced Models with Better Live Stream Support
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
    
    // Computed properties for better stream handling
    var isOnline: Bool {
        return broadcasting_status?.lowercased() == "online"
    }
    
    var bestStreamURL: String? {
        // Prioritize HLS URLs for live streaming
        if let hlsURL = hls_url ?? playback?.hls_url {
            return hlsURL
        }
        
        // Fallback to embed URL
        return embed_url ?? playback?.embed_url
    }
    
    var isValidForStreaming: Bool {
        guard enabled else { return false }
        return bestStreamURL != nil
    }
    
    var statusColor: Color {
        switch broadcasting_status?.lowercased() {
        case "online":
            return .red
        case "offline":
            return .gray
        default:
            return .orange
        }
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

// MARK: - Show Model (renamed from Video)
struct Show: Codable, Identifiable {
    let id = UUID()
    let _id: String
    let name: String
    let enabled: Bool
    let type: String
    let creation_time: String
    let episodes: [Episode] // renamed from data
    let user: String
    
    enum CodingKeys: String, CodingKey {
        case _id, name, enabled, type, creation_time, episodes = "data", user
    }
    
    // Computed properties for show organization
    var displayName: String {
        return name
    }
    
    var episodeCount: Int {
        return episodes.filter { $0.enabled }.count
    }
    
    var latestEpisode: Episode? {
        let sortedEpisodes = episodes
            .filter { $0.enabled }
            .sorted { episode1, episode2 in
                let dateFormatter = ISO8601DateFormatter()
                let date1 = dateFormatter.date(from: episode1.creationTime) ?? Date.distantPast
                let date2 = dateFormatter.date(from: episode2.creationTime) ?? Date.distantPast
                return date1 > date2
            }
        return sortedEpisodes.first
    }
    
    var showCategory: ShowCategory {
        let showName = name.lowercased()
        
        if showName.contains("truth") && showName.contains("matters") {
            return .biblicalTeaching
        } else if showName.contains("ct townsend") || showName.contains("fresh oil") {
            return .inspirational
        } else if showName.contains("sandra hancock") || showName.contains("voice of hope") {
            return .ministry
        } else if showName.contains("ignited church") || showName.contains("grace pointe") {
            return .church
        } else if showName.contains("evangelistic") || showName.contains("higher praise") {
            return .worship
        } else if showName.contains("second chances") {
            return .testimony
        } else {
            return .general
        }
    }
}

// MARK: - Episode Model (renamed from VideoData)
struct Episode: Codable, Identifiable {
    let id = UUID()
    let episodeId: String // renamed from dataId
    let fileName: String
    let enabled: Bool
    let bytes: Int
    let mediaInfo: MediaInfo?
    let encodingRequired: Bool
    let precedence: Int
    let author: String
    let creationTime: String
    let _id: String
    let playback: EpisodePlayback? // renamed from VideoPlayback
    
    enum CodingKeys: String, CodingKey {
        case episodeId = "id", fileName, enabled, bytes, mediaInfo, encodingRequired, precedence, author, creationTime, _id, playback
    }
    
    // Computed properties for episode organization
    var displayTitle: String {
        return fileName.replacingOccurrences(of: ".mp4", with: "")
    }
    
    var episodeNumber: Int? {
        let patterns = [
            #"ep\s*(\d+)"#,
            #"episode\s*(\d+)"#,
            #"part\s*(\d+)"#,
            #"pt\s*(\d+)"#
        ]
        
        let lowercaseFileName = fileName.lowercased()
        
        for pattern in patterns {
            let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
            let range = NSRange(location: 0, length: lowercaseFileName.count)
            
            if let match = regex?.firstMatch(in: lowercaseFileName, options: [], range: range),
               let numberRange = Range(match.range(at: 1), in: lowercaseFileName) {
                let numberString = String(lowercaseFileName[numberRange])
                return Int(numberString)
            }
        }
        
        return nil
    }
    
    var airDate: Date? {
        let dateFormatter = ISO8601DateFormatter()
        return dateFormatter.date(from: creationTime)
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

struct EpisodePlayback: Codable { // renamed from VideoPlayback
    let embed_url: String?
    let hls_url: String?
}

// MARK: - Show Category Enum
enum ShowCategory: String, CaseIterable, Identifiable {
    case all = "All Shows"
    case biblicalTeaching = "Biblical Teaching"
    case ministry = "Ministry & Outreach"
    case church = "Church Services"
    case inspirational = "Inspirational"
    case worship = "Worship & Praise"
    case testimony = "Testimonies"
    case liveStreams = "Live Streams"
    case general = "General"
    
    var id: String { self.rawValue }
    
    var color: Color {
        switch self {
        case .all:
            return Color(red: 0.2, green: 0.6, blue: 1.0)
        case .biblicalTeaching:
            return Color(red: 0.8, green: 0.4, blue: 0.2)
        case .ministry:
            return Color(red: 0.3, green: 0.7, blue: 0.4)
        case .church:
            return Color(red: 0.6, green: 0.2, blue: 0.8)
        case .inspirational:
            return Color(red: 1.0, green: 0.7, blue: 0.3)
        case .worship:
            return Color(red: 0.9, green: 0.3, blue: 0.9)
        case .testimony:
            return Color(red: 0.2, green: 0.8, blue: 0.8)
        case .liveStreams:
            return Color.red
        case .general:
            return Color(red: 0.5, green: 0.5, blue: 0.8)
        }
    }
    
    var icon: String {
        switch self {
        case .all:
            return "tv.and.hifispeaker.fill"
        case .biblicalTeaching:
            return "book.closed.fill"
        case .ministry:
            return "building.2.crop.circle.fill"
        case .church:
            return "building.fill"
        case .inspirational:
            return "heart.circle.fill"
        case .worship:
            return "hands.sparkles.fill"
        case .testimony:
            return "person.fill.questionmark"
        case .liveStreams:
            return "dot.radiowaves.left.and.right"
        case .general:
            return "tv.circle.fill"
        }
    }
}

// MARK: - Show Collection Model
struct ShowCollection: Identifiable {
    let id = UUID()
    let category: ShowCategory
    let shows: [Show]
    
    var displayTitle: String {
        return category.rawValue
    }
    
    var showCount: Int {
        return shows.count
    }
    
    var totalEpisodes: Int {
        return shows.reduce(0) { $0 + $1.episodeCount }
    }
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

// MARK: - API Response Models
struct ShowsResponse: Codable { // renamed from VideosResponse
    let total: Int
    let page: Int
    let pages: Int
    let docs: [Show] // renamed from Video
}

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

// MARK: - Backward Compatibility Types
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
    
    // Helper initializer for creating from Episode
    init(from episode: Episode) {
        self.dataId = episode.episodeId
        self.fileName = episode.fileName
        self.enabled = episode.enabled
        self.bytes = episode.bytes
        self.mediaInfo = episode.mediaInfo
        self.encodingRequired = episode.encodingRequired
        self.precedence = episode.precedence
        self.author = episode.author
        self.creationTime = episode.creationTime
        self._id = episode._id
        self.playback = VideoPlayback(
            embed_url: episode.playback?.embed_url,
            hls_url: episode.playback?.hls_url
        )
    }
    
    // Default initializer
    init(dataId: String, fileName: String, enabled: Bool, bytes: Int, mediaInfo: MediaInfo?, encodingRequired: Bool, precedence: Int, author: String, creationTime: String, _id: String, playback: VideoPlayback?) {
        self.dataId = dataId
        self.fileName = fileName
        self.enabled = enabled
        self.bytes = bytes
        self.mediaInfo = mediaInfo
        self.encodingRequired = encodingRequired
        self.precedence = precedence
        self.author = author
        self.creationTime = creationTime
        self._id = _id
        self.playback = playback
    }
}

struct VideoPlayback: Codable {
    let embed_url: String?
    let hls_url: String?
    
    init(embed_url: String?, hls_url: String?) {
        self.embed_url = embed_url
        self.hls_url = hls_url
    }
}

struct Category: Identifiable {
    let id = UUID()
    let name: String
    let image: String
    let color: Color
    let videos: [VideoData]
    
    init(name: String, image: String, color: Color, videos: [VideoData]) {
        self.name = name
        self.image = image
        self.color = color
        self.videos = videos
    }
}

// MARK: - Stream Validation Extensions
extension LiveStream {
    func validateStreamURL() -> StreamValidationResult {
        guard enabled else {
            return .invalid("Stream is disabled")
        }
        
        guard let urlString = bestStreamURL else {
            return .invalid("No valid stream URL found")
        }
        
        guard let url = URL(string: urlString) else {
            return .invalid("Invalid URL format")
        }
        
        // Check if it's an HLS stream
        if urlString.contains(".m3u8") {
            return .valid(.hls(url))
        }
        
        // Check if it's an embed URL that might contain HLS
        if urlString.contains("embed") || urlString.contains("iframe") {
            return .valid(.embed(url))
        }
        
        return .invalid("Unsupported stream format")
    }
}

enum StreamValidationResult {
    case valid(StreamType)
    case invalid(String)
}

enum StreamType {
    case hls(URL)
    case embed(URL)
    case mp4(URL)
}

// MARK: - HLS Stream Testing
struct HLSStreamTester {
    static func testStreamURL(_ urlString: String, completion: @escaping (Bool, String?) -> Void) {
        guard let url = URL(string: urlString) else {
            completion(false, "Invalid URL")
            return
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "HEAD"
        request.timeoutInterval = 10.0
        
        // Add headers for better compatibility
        request.setValue("application/vnd.apple.mpegurl", forHTTPHeaderField: "Accept")
        request.setValue("AVFoundation/1.0", forHTTPHeaderField: "User-Agent")
        
        URLSession.shared.dataTask(with: request) { _, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(false, "Network error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    let statusCode = httpResponse.statusCode
                    let isValid = (200...299).contains(statusCode)
                    
                    if isValid {
                        // Check content type for HLS
                        let contentType = httpResponse.value(forHTTPHeaderField: "Content-Type")
                        if contentType?.contains("mpegurl") == true || contentType?.contains("m3u8") == true {
                            completion(true, "Valid HLS stream")
                        } else {
                            completion(true, "Stream accessible (HTTP \(statusCode))")
                        }
                    } else {
                        completion(false, "HTTP \(statusCode)")
                    }
                } else {
                    completion(false, "Invalid response")
                }
            }
        }.resume()
    }
}

// MARK: - DateFormatter Extension
extension DateFormatter {
    static let episodeDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()
}
