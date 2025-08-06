import SwiftUI
import Foundation
import AVKit
import UIKit

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
                    
                    var allVideoData: [VideoData] = []
                    for video in response.docs where video.enabled {
                        allVideoData.append(contentsOf: video.data)
                    }
                    
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
    
   
    
    private func handleError(_ message: String) {
        errorMessage = message
        isLoading = false
        print("Error: \(message)")
    }
    
    func loadThumbnail(for videoData: VideoData) {
        // Set loading state
        DispatchQueue.main.async {
            self.thumbnailStates[videoData._id] = .loading
        }
        
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

// MARK: - CastrAPIService Extension for Enhanced Categorization
extension CastrAPIService {
    
    // Replace the existing createCategories method with this enhanced version
    func createCategories(from videoData: [VideoData]) {
        let allVideos = videoData
        var categories: [Category] = []
        
        // 1. All Videos Category (Always first)
        categories.append(Category(
            name: "All Videos",
            image: "all_videos",
            color: Color(red: 0.2, green: 0.6, blue: 1.0),
            videos: allVideos
        ))
        
        // 2. Recent Uploads (Last 30 days)
        let recentVideos = getRecentVideos(from: allVideos, days: 30)
        if !recentVideos.isEmpty {
            categories.append(Category(
                name: "Recently Added",
                image: "recent_videos",
                color: Color(red: 0.9, green: 0.3, blue: 0.9),
                videos: recentVideos
            ))
        }
        
        // 3. Ministries & Churches
        let ministryVideos = allVideos.filter { video in
            let fileName = video.fileName.lowercased()
            let author = video.author.lowercased()
            return fileName.contains("ministries") ||
                   fileName.contains("church") ||
                   fileName.contains("ct townsend") ||
                   fileName.contains("sandra hancock") ||
                   fileName.contains("ignited church") ||
                   fileName.contains("grace pointe") ||
                   fileName.contains("united christian") ||
                   fileName.contains("evangelistic") ||
                   fileName.contains("higher praise") ||
                   fileName.contains("oasis") ||
                   author.contains("oasis") ||
                   author.contains("greaterlove")
        }
        if !ministryVideos.isEmpty {
            categories.append(Category(
                name: "Ministries & Churches",
                image: "ministries",
                color: Color(red: 0.3, green: 0.7, blue: 0.4),
                videos: ministryVideos
            ))
        }
        
        // 4. Teaching & Truth Series
        let teachingVideos = allVideos.filter { video in
            let fileName = video.fileName.lowercased()
            return fileName.contains("truth") ||
                   fileName.contains("matters") ||
                   fileName.contains("teaching") ||
                   fileName.contains("biblical") ||
                   fileName.contains("study") ||
                   fileName.contains("lesson") ||
                   fileName.contains("works of god") ||
                   fileName.contains("faith over fear")
        }
        if !teachingVideos.isEmpty {
            categories.append(Category(
                name: "Biblical Teaching",
                image: "teaching",
                color: Color(red: 0.8, green: 0.4, blue: 0.2),
                videos: teachingVideos
            ))
        }
        
        // 5. Inspirational & Testimony
        let inspirationalVideos = allVideos.filter { video in
            let fileName = video.fileName.lowercased()
            return fileName.contains("testimony") ||
                   fileName.contains("hope") ||
                   fileName.contains("inspiration") ||
                   fileName.contains("voice of hope") ||
                   fileName.contains("fresh oil") ||
                   fileName.contains("second chances") ||
                   fileName.contains("emily testimony") ||
                   fileName.contains("prophecy") ||
                   fileName.contains("promise") ||
                   fileName.contains("pain precedes") ||
                   fileName.contains("naked") ||
                   fileName.contains("afraid")
        }
        if !inspirationalVideos.isEmpty {
            categories.append(Category(
                name: "Inspirational & Testimony",
                image: "inspirational",
                color: Color(red: 1.0, green: 0.7, blue: 0.3),
                videos: inspirationalVideos
            ))
        }
        
        // 6. Biblical Studies (Books of the Bible)
        let biblicalStudyVideos = allVideos.filter { video in
            let fileName = video.fileName.lowercased()
            return fileName.contains("daniel") ||
                   fileName.contains("acts") ||
                   fileName.contains("psalms") ||
                   fileName.contains("john") ||
                   fileName.contains("matthew") ||
                   fileName.contains("romans") ||
                   fileName.contains("genesis") ||
                   fileName.contains("revelation") ||
                   fileName.range(of: "daniel \\d+", options: .regularExpression) != nil ||
                   fileName.range(of: "psalms \\d+", options: .regularExpression) != nil
        }
        if !biblicalStudyVideos.isEmpty {
            categories.append(Category(
                name: "Biblical Studies",
                image: "biblical_studies",
                color: Color(red: 0.4, green: 0.3, blue: 0.8),
                videos: biblicalStudyVideos
            ))
        }
        
        // 7. Faith & Worship
        let faithVideos = allVideos.filter { video in
            let fileName = video.fileName.lowercased()
            return fileName.contains("faith") ||
                   fileName.contains("worship") ||
                   fileName.contains("praise") ||
                   fileName.contains("prayer") ||
                   fileName.contains("refuge") ||
                   fileName.contains("closer") ||
                   fileName.contains("awaken") ||
                   fileName.contains("god is my refuge") ||
                   fileName.contains("closer than before") ||
                   fileName.contains("land of good enough")
        }
        if !faithVideos.isEmpty {
            categories.append(Category(
                name: "Faith & Worship",
                image: "faith_worship",
                color: Color(red: 0.6, green: 0.2, blue: 0.8),
                videos: faithVideos
            ))
        }
        
        // 8. Series & Shows (Episode-based content)
        let seriesVideos = allVideos.filter { video in
            let fileName = video.fileName.lowercased()
            return fileName.contains("ep") ||
                   fileName.contains("episode") ||
                   fileName.contains("part") ||
                   fileName.contains("pt") ||
                   fileName.contains("series") ||
                   fileName.contains("show") ||
                   fileName.range(of: "ep\\d+", options: .regularExpression) != nil ||
                   fileName.range(of: "part \\d+", options: .regularExpression) != nil
        }
        if !seriesVideos.isEmpty {
            categories.append(Category(
                name: "Series & Shows",
                image: "series_shows",
                color: Color(red: 0.2, green: 0.8, blue: 0.8),
                videos: seriesVideos
            ))
        }
        
        // 9. Live Content & Events
        let liveVideos = allVideos.filter { video in
            let fileName = video.fileName.lowercased()
            return fileName.contains("live") ||
                   fileName.contains("stream") ||
                   fileName.contains("event") ||
                   fileName.contains("broadcast") ||
                   fileName.contains("replay") ||
                   fileName.contains("airdate")
        }
        if !liveVideos.isEmpty {
            categories.append(Category(
                name: "Live & Events",
                image: "live_events",
                color: Color.red,
                videos: liveVideos
            ))
        }
        
        // 10. Author-based categories for prominent authors
        createAuthorBasedCategories(from: allVideos, categories: &categories)
        
        // Sort categories by video count (except "All Videos" which stays first)
        let allVideosCategory = categories.first { $0.name == "All Videos" }
        let otherCategories = categories.filter { $0.name != "All Videos" }
            .sorted { $0.videos.count > $1.videos.count }
        
        var finalCategories: [Category] = []
        if let allVideos = allVideosCategory {
            finalCategories.append(allVideos)
        }
        finalCategories.append(contentsOf: otherCategories)
        
        self.categories = finalCategories
    }
    
    // MARK: - Helper Methods for Enhanced Categorization
    
    private func getRecentVideos(from videos: [VideoData], days: Int) -> [VideoData] {
        let calendar = Calendar.current
        let cutoffDate = calendar.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let dateFormatter = ISO8601DateFormatter()
        
        return videos.filter { video in
            guard let date = dateFormatter.date(from: video.creationTime) else { return false }
            return date > cutoffDate
        }.sorted { video1, video2 in
            let date1 = dateFormatter.date(from: video1.creationTime) ?? Date.distantPast
            let date2 = dateFormatter.date(from: video2.creationTime) ?? Date.distantPast
            return date1 > date2
        }
    }
    
    private func createAuthorBasedCategories(from videos: [VideoData], categories: inout [Category]) {
        // Group videos by author
        let authorGroups = Dictionary(grouping: videos) { $0.author }
        
        // Create categories for authors with significant content (5+ videos)
        let significantAuthors = authorGroups.filter { $1.count >= 5 }
        
        for (author, authorVideos) in significantAuthors {
            let authorName = getReadableAuthorName(from: author)
            
            // Skip if we already have a more specific category for this content
            if !shouldCreateAuthorCategory(for: authorName, videos: authorVideos) {
                continue
            }
            
            categories.append(Category(
                name: authorName,
                image: "author_\(author)",
                color: getAuthorColor(for: author),
                videos: authorVideos.sorted { video1, video2 in
                    let dateFormatter = ISO8601DateFormatter()
                    let date1 = dateFormatter.date(from: video1.creationTime) ?? Date.distantPast
                    let date2 = dateFormatter.date(from: video2.creationTime) ?? Date.distantPast
                    return date1 > date2
                }
            ))
        }
    }
    
    private func getReadableAuthorName(from email: String) -> String {
        // Convert email to readable name
        if email.contains("kaylen@greaterlove.tv") {
            return "Greater Love Productions"
        } else if email.contains("angel@oasisministries.com") {
            return "Oasis Ministries"
        } else {
            // Extract name from email
            let username = email.components(separatedBy: "@").first ?? email
            return username.capitalized.replacingOccurrences(of: ".", with: " ")
        }
    }
    
    private func shouldCreateAuthorCategory(for authorName: String, videos: [VideoData]) -> Bool {
        // Don't create author categories if the content is better categorized elsewhere
        if authorName.contains("Greater Love") && videos.count < 10 {
            return false
        }
        return true
    }
    
    private func getAuthorColor(for author: String) -> Color {
        // Assign consistent colors based on author
        switch author {
        case let email where email.contains("kaylen"):
            return Color(red: 0.9, green: 0.4, blue: 0.1)
        case let email where email.contains("angel"):
            return Color(red: 0.1, green: 0.6, blue: 0.9)
        default:
            return Color(red: 0.5, green: 0.5, blue: 0.8)
        }
    }
    
    // MARK: - Category Analytics
    
    func getCategoryAnalytics() -> [String: Any] {
        var analytics: [String: Any] = [:]
        
        analytics["total_categories"] = categories.count
        analytics["total_videos"] = videoData.count
        analytics["average_videos_per_category"] = categories.isEmpty ? 0 : videoData.count / categories.count
        
        let categorySizes = categories.map { ($0.name, $0.videos.count) }
        analytics["largest_category"] = categorySizes.max { $0.1 < $1.1 }
        analytics["smallest_category"] = categorySizes.min { $0.1 < $1.1 }
        
        return analytics
    }
    
    // MARK: - Search and Filter Methods
    
    func searchVideos(query: String) -> [VideoData] {
        let lowercaseQuery = query.lowercased()
        
        return videoData.filter { video in
            video.fileName.lowercased().contains(lowercaseQuery) ||
            video.author.lowercased().contains(lowercaseQuery)
        }.sorted { video1, video2 in
            let dateFormatter = ISO8601DateFormatter()
            let date1 = dateFormatter.date(from: video1.creationTime) ?? Date.distantPast
            let date2 = dateFormatter.date(from: video2.creationTime) ?? Date.distantPast
            return date1 > date2
        }
    }
    
    func getVideosFromCategory(named categoryName: String) -> [VideoData] {
        return categories.first { $0.name == categoryName }?.videos ?? []
    }
    
    func getPopularCategories(limit: Int = 5) -> [Category] {
        return categories
            .filter { $0.name != "All Videos" }
            .sorted { $0.videos.count > $1.videos.count }
            .prefix(limit)
            .map { $0 }
    }
}
