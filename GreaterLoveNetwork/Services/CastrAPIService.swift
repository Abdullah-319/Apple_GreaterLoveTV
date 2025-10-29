import SwiftUI
import Foundation
import AVKit
import UIKit

// MARK: - Enhanced API Service for Shows and Episodes (Fixed Debug-Free Version)
class CastrAPIService: ObservableObject {
    private let baseURL = "https://api.castr.com/v2"
    private let wordPressBaseURL = "https://greaterlove.tv/wp-json/myplugin/v1"
    private let accessToken = "5aLoKjrNjly4"
    private let secretKey = "UjTCq8wOj76vjXznGFzdbMRzAkFq6VlJElBQ"
    
    @Published var liveStreams: [LiveStream] = []
    @Published var shows: [Show] = []
    @Published var allEpisodes: [Episode] = []
    @Published var showCollections: [ShowCollection] = []
    @Published var recordings: [Recording] = []
    @Published var featuredShows: [Show] = []
    @Published var featuredMinisters: [String: [Show]] = [:]
    @Published var isLoading = false
    @Published var isLoadingMoreShows = false
    @Published var errorMessage: String?
    @Published var thumbnailStates: [String: ThumbnailState] = [:]
    
    // Pagination state
    @Published var currentPage = 1
    @Published var totalPages = 1
    @Published var hasMorePages = false
    
    // Backward compatibility properties
    @Published var videos: [Show] = []
    @Published var videoData: [VideoData] = []
    @Published var categories: [Category] = []
    
    private var authHeader: String {
        let credentials = "\(accessToken):\(secretKey)"
        let credentialsData = credentials.data(using: .utf8)!
        let base64Credentials = credentialsData.base64EncodedString()
        return "Basic \(base64Credentials)"
    }
    
    func fetchAllContent() {
        addStaticLiveStreams()
        fetchWordPressVOD()
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
    
    // MARK: - WordPress VOD API Methods

    func fetchWordPressVOD() {
        isLoading = true
        print("🎬 Starting WordPress VOD fetch...")

        guard let url = URL(string: "\(wordPressBaseURL)/castrvod") else {
            handleError("Invalid WordPress VOD URL")
            return
        }

        print("📡 Fetching from: \(url.absoluteString)")

        var request = URLRequest(url: url)
        request.setValue("Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15", forHTTPHeaderField: "User-Agent")
        request.setValue("application/json, text/plain, */*", forHTTPHeaderField: "Accept")
        request.setValue("https://greaterlove.tv/", forHTTPHeaderField: "Referer")

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("❌ Network Error: \(error.localizedDescription)")
                    self?.handleError("Network Error: \(error.localizedDescription)")
                    return
                }

                if let httpResponse = response as? HTTPURLResponse {
                    print("📊 HTTP Status Code: \(httpResponse.statusCode)")
                }

                guard let data = data else {
                    print("❌ No data received")
                    self?.handleError("No data received from WordPress API")
                    return
                }

                print("✅ Data received: \(data.count) bytes")

                // Try to print raw JSON for debugging
                if let jsonString = String(data: data, encoding: .utf8) {
                    print("📄 Raw JSON (first 500 chars): \(String(jsonString.prefix(500)))")
                }

                do {
                    let wpResponse = try JSONDecoder().decode(WordPressVODResponse.self, from: data)
                    print("✅ Successfully decoded WordPress response")
                    print("📊 Total shows: \(wpResponse.totalShows)")
                    print("📊 Data keys count: \(wpResponse.data.count)")

                    // Convert WordPress data to Show/Episode models
                    let convertedShows = self?.convertWordPressDataToShows(wpResponse)
                    print("✅ Converted \(convertedShows?.count ?? 0) shows")

                    // Update shows and episodes
                    self?.shows = convertedShows ?? []

                    // Extract all episodes
                    var allEps: [Episode] = []
                    for show in convertedShows ?? [] {
                        allEps.append(contentsOf: show.episodes)
                    }
                    self?.allEpisodes = allEps
                    print("✅ Total episodes: \(allEps.count)")

                    // Update backward compatibility properties
                    self?.videos = self?.shows ?? []
                    self?.videoData = allEps.compactMap { episode in
                        return self?.convertEpisodeToVideoData(episode)
                    }

                    // Update collections and categories
                    self?.createShowCollections(from: self?.shows ?? [])
                    self?.createCategories(from: self?.allEpisodes ?? [])

                    // Process featured content
                    self?.processFeaturedContent()

                    print("🎉 WordPress VOD fetch completed successfully!")
                    print("📺 Shows: \(self?.shows.count ?? 0)")
                    print("🎬 Episodes: \(self?.allEpisodes.count ?? 0)")

                    self?.isLoading = false

                } catch {
                    print("❌ Decoding error: \(error)")
                    if let decodingError = error as? DecodingError {
                        switch decodingError {
                        case .keyNotFound(let key, let context):
                            print("Missing key: \(key.stringValue) - \(context.debugDescription)")
                        case .typeMismatch(let type, let context):
                            print("Type mismatch for type: \(type) - \(context.debugDescription)")
                        case .valueNotFound(let type, let context):
                            print("Value not found for type: \(type) - \(context.debugDescription)")
                        case .dataCorrupted(let context):
                            print("Data corrupted: \(context.debugDescription)")
                        @unknown default:
                            print("Unknown decoding error")
                        }
                    }
                    self?.handleError("Failed to decode WordPress VOD data: \(error.localizedDescription)")
                }
            }
        }.resume()
    }

    private func convertWordPressDataToShows(_ wpResponse: WordPressVODResponse) -> [Show] {
        var shows: [Show] = []

        for (showName, wpShow) in wpResponse.data {
            // Convert WordPress episodes to Episode models
            let episodes = wpShow.episodes.map { wpEpisode -> Episode in
                let playback = EpisodePlayback(
                    embed_url: wpEpisode.embedUrl,
                    hls_url: wpEpisode.directUrl
                )

                // Convert WordPress date format to ISO8601
                let creationTime: String
                if let date = DateFormatter.wordpressDate.date(from: wpEpisode.createdAt) {
                    let isoFormatter = ISO8601DateFormatter()
                    creationTime = isoFormatter.string(from: date)
                } else {
                    creationTime = wpEpisode.createdAt
                }

                return Episode(
                    episodeId: String(wpEpisode.id),
                    fileName: wpEpisode.episodeName,
                    enabled: true,
                    bytes: 0,
                    mediaInfo: nil,
                    encodingRequired: false,
                    precedence: wpEpisode.id,
                    author: wpEpisode.showName,
                    creationTime: creationTime,
                    _id: String(wpEpisode.id),
                    playback: playback
                )
            }

            // Create Show model
            let show = Show(
                _id: showName.replacingOccurrences(of: " ", with: "_").lowercased(),
                name: showName,
                enabled: true,
                type: "vod",
                creation_time: episodes.first?.creationTime ?? ISO8601DateFormatter().string(from: Date()),
                episodes: episodes,
                user: "wordpress",
                imageUrl: wpShow.imageUrl
            )

            shows.append(show)
        }

        // Sort shows alphabetically
        return shows.sorted { $0.name < $1.name }
    }

    // MARK: - Pagination Methods

    func fetchAllShowsWithPagination() {
        isLoading = true
        currentPage = 1
        shows.removeAll()
        allEpisodes.removeAll()
        fetchShowsPage(page: 1, isInitialLoad: true)
    }
    
    func loadMoreShows() {
        guard !isLoadingMoreShows && hasMorePages else { return }
        
        isLoadingMoreShows = true
        currentPage += 1
        fetchShowsPage(page: currentPage, isInitialLoad: false)
    }
    
    private func fetchShowsPage(page: Int, isInitialLoad: Bool) {
        guard let url = URL(string: "\(baseURL)/videos?page=\(page)") else {
            handleError("Invalid URL for page \(page)")
            return
        }
        
        var request = URLRequest(url: url)
        request.setValue(authHeader, forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            DispatchQueue.main.async {
                if let error = error {
                    self?.handleError("Network Error: \(error.localizedDescription)")
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 {
                        self?.handleError("Authentication failed. Please check your API credentials.")
                        return
                    }
                }
                
                guard let data = data else {
                    self?.handleError("No data received")
                    return
                }
                
                do {
                    let response = try JSONDecoder().decode(ShowsResponse.self, from: data)
                    
                    // Update pagination info
                    self?.totalPages = response.pages
                    self?.hasMorePages = page < response.pages
                    
                    // Filter enabled shows
                    let enabledShows = response.docs.filter { $0.enabled }
                    
                    // Append new shows to existing shows (for pagination)
                    if isInitialLoad {
                        self?.shows = enabledShows
                    } else {
                        self?.shows.append(contentsOf: enabledShows)
                    }
                    
                    // Process episodes
                    var pageEpisodes: [Episode] = []
                    for show in enabledShows {
                        let enabledEpisodes = show.episodes.filter { $0.enabled }
                        pageEpisodes.append(contentsOf: enabledEpisodes)
                    }
                    
                    if isInitialLoad {
                        self?.allEpisodes = pageEpisodes
                    } else {
                        self?.allEpisodes.append(contentsOf: pageEpisodes)
                    }
                    
                    // Update backward compatibility properties
                    self?.videos = self?.shows ?? []
                    self?.videoData = (self?.allEpisodes ?? []).compactMap { episode in
                        return self?.convertEpisodeToVideoData(episode)
                    }
                    
                    // Update collections and categories
                    self?.createShowCollections(from: self?.shows ?? [])
                    self?.createCategories(from: self?.allEpisodes ?? [])
                    
                    // Process featured content
                    self?.processFeaturedContent()
                    
                    // Update loading states
                    if isInitialLoad {
                        self?.isLoading = false
                    } else {
                        self?.isLoadingMoreShows = false
                    }
                    
                } catch {
                    self?.handleError("Failed to decode shows: \(error.localizedDescription)")
                    if isInitialLoad {
                        self?.isLoading = false
                    } else {
                        self?.isLoadingMoreShows = false
                    }
                }
            }
        }.resume()
    }
    
    // MARK: - Featured Content Processing
    
    private let featuredShowNames = [
        "CT Townsend",
        "Truth Matters",
        "Sandra Hancock Ministries",
        "Ignited Church",
        "Fresh Oil",
        "Grace Pointe Church"
    ]
    
    private let featuredMinisterNames = [
        "CT Townsend",
        "Sandra Hancock",
        "Angel Martinez",
        "Kaylen Smith",
        "Tim Johnson",
        "Mark Davis"
    ]
    
    private func processFeaturedContent() {
        // Process featured shows by name
        var featured: [Show] = []
        
        for showName in featuredShowNames {
            if let show = shows.first(where: {
                $0.displayName.lowercased().contains(showName.lowercased()) ||
                showName.lowercased().contains($0.displayName.lowercased())
            }) {
                featured.append(show)
            }
        }
        
        // If we don't have enough featured shows by name, add top shows by episode count
        let remainingCount = max(0, 6 - featured.count)
        let topShows = shows
            .filter { show in !featured.contains { $0._id == show._id } }
            .sorted { $0.episodeCount > $1.episodeCount }
            .prefix(remainingCount)
        
        featured.append(contentsOf: topShows)
        
        self.featuredShows = Array(featured.prefix(6))
        
        // Process featured ministers
        var ministers: [String: [Show]] = [:]
        
        for ministerName in featuredMinisterNames {
            let ministerShows = shows.filter { show in
                show.episodes.contains { episode in
                    episode.author.lowercased().contains(ministerName.lowercased()) ||
                    ministerName.lowercased().contains(episode.author.lowercased()) ||
                    show.displayName.lowercased().contains(ministerName.lowercased())
                }
            }
            
            if !ministerShows.isEmpty {
                ministers[ministerName] = Array(ministerShows.prefix(3))
            }
        }
        
        self.featuredMinisters = ministers
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
                    return
                }
                
                if let httpResponse = response as? HTTPURLResponse {
                    if httpResponse.statusCode == 401 {
                        return
                    }
                }
                
                guard let data = data else {
                    return
                }
                
                do {
                    let streams = try JSONDecoder().decode([LiveStream].self, from: data)
                    let apiStreams = streams.filter { $0.enabled }
                    self?.liveStreams.append(contentsOf: apiStreams)
                } catch {
                    do {
                        if let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any] {
                            if let dataArray = jsonObject["data"] as? [[String: Any]] {
                                let jsonData = try JSONSerialization.data(withJSONObject: dataArray)
                                let streams = try JSONDecoder().decode([LiveStream].self, from: jsonData)
                                let apiStreams = streams.filter { $0.enabled }
                                self?.liveStreams.append(contentsOf: apiStreams)
                            }
                        }
                    } catch {
                        // Silently handle error
                    }
                }
            }
        }.resume()
    }
    
    private func handleError(_ message: String) {
        errorMessage = message
        isLoading = false
        isLoadingMoreShows = false
    }
    
    func loadThumbnail(for episode: Episode) {
        // Set loading state
        DispatchQueue.main.async {
            self.thumbnailStates[episode._id] = .loading
        }
        
        guard let embedURL = episode.playback?.embed_url else {
            DispatchQueue.main.async {
                self.thumbnailStates[episode._id] = .failed
            }
            return
        }
        
        extractMP4URL(from: embedURL) { [weak self] extractedURL in
            guard let extractedURL = extractedURL else {
                DispatchQueue.main.async {
                    self?.thumbnailStates[episode._id] = .failed
                }
                return
            }
            
            if extractedURL.contains(".m3u8") {
                self?.generateThumbnailFromHLS(extractedURL, for: episode)
            } else {
                self?.generateThumbnailFromMP4(extractedURL, for: episode)
            }
        }
    }
    
    // Backward compatibility method
    func loadThumbnail(for videoData: VideoData) {
        let episode = Episode(
            episodeId: videoData.dataId,
            fileName: videoData.fileName,
            enabled: videoData.enabled,
            bytes: videoData.bytes,
            mediaInfo: videoData.mediaInfo,
            encodingRequired: videoData.encodingRequired,
            precedence: videoData.precedence,
            author: videoData.author,
            creationTime: videoData.creationTime,
            _id: videoData._id,
            playback: EpisodePlayback(
                embed_url: videoData.playback?.embed_url,
                hls_url: videoData.playback?.hls_url
            )
        )
        loadThumbnail(for: episode)
    }
    
    // MARK: - Helper method to convert Episode to VideoData
    func convertEpisodeToVideoData(_ episode: Episode) -> VideoData {
        return VideoData(
            dataId: episode.episodeId,
            fileName: episode.fileName,
            enabled: episode.enabled,
            bytes: episode.bytes,
            mediaInfo: episode.mediaInfo,
            encodingRequired: episode.encodingRequired,
            precedence: episode.precedence,
            author: episode.author,
            creationTime: episode.creationTime,
            _id: episode._id,
            playback: VideoPlayback(
                embed_url: episode.playback?.embed_url,
                hls_url: episode.playback?.hls_url
            )
        )
    }
    
    // MARK: - Fixed MP4 URL Extraction with Better Error Handling
    func extractMP4URL(from embedURL: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: embedURL) else {
            completion(nil)
            return
        }
        
        // Create URL session with timeout
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = 15.0
        config.timeoutIntervalForResource = 30.0
        let session = URLSession(configuration: config)
        
        session.dataTask(with: url) { data, response, error in
            // Handle network errors
            if let error = error {
                completion(nil)
                return
            }
            
            guard let data = data,
                  let htmlString = String(data: data, encoding: .utf8) else {
                completion(nil)
                return
            }
            
            // Enhanced URL extraction patterns
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
            
            // Fallback pattern matching for Castr VOD URLs
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
    
    private func generateThumbnailFromHLS(_ hlsURL: String, for episode: Episode) {
        guard let url = URL(string: hlsURL) else {
            DispatchQueue.main.async {
                self.thumbnailStates[episode._id] = .failed
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
                        self?.thumbnailStates[episode._id] = .loaded(thumbnail)
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.thumbnailStates[episode._id] = .failed
                    }
                }
            }
        }
    }
    
    private func generateThumbnailFromMP4(_ mp4URL: String, for episode: Episode) {
        guard let url = URL(string: mp4URL) else {
            DispatchQueue.main.async {
                self.thumbnailStates[episode._id] = .failed
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
                        self?.thumbnailStates[episode._id] = .loaded(thumbnail)
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.thumbnailStates[episode._id] = .failed
                    }
                }
            }
        }
    }
    
    // MARK: - Featured Content Getters
    
    func getFeaturedShows(limit: Int = 6) -> [Show] {
        return Array(featuredShows.prefix(limit))
    }
    
    func getFeaturedMinisters() -> [String: [Show]] {
        return featuredMinisters
    }
    
    func getShowsByMinister(_ ministerName: String) -> [Show] {
        return featuredMinisters[ministerName] ?? []
    }
    
    func getTopFeaturedMinisters(limit: Int = 6) -> [(String, [Show])] {
        return Array(featuredMinisters
            .sorted { $0.value.count > $1.value.count }
            .prefix(limit))
    }
    
    // MARK: - Search and Filter Methods
    
    func searchShows(query: String) -> [Show] {
        let lowercaseQuery = query.lowercased()
        
        return shows.filter { show in
            show.displayName.lowercased().contains(lowercaseQuery) ||
            show.showCategory.rawValue.lowercased().contains(lowercaseQuery)
        }.sorted { show1, show2 in
            let name1 = show1.displayName.lowercased()
            let name2 = show2.displayName.lowercased()
            
            if name1.hasPrefix(lowercaseQuery) && !name2.hasPrefix(lowercaseQuery) {
                return true
            } else if !name1.hasPrefix(lowercaseQuery) && name2.hasPrefix(lowercaseQuery) {
                return false
            } else {
                return show1.episodeCount > show2.episodeCount
            }
        }
    }
    
    func searchEpisodes(query: String) -> [Episode] {
        let lowercaseQuery = query.lowercased()
        
        return allEpisodes.filter { episode in
            episode.displayTitle.lowercased().contains(lowercaseQuery) ||
            episode.author.lowercased().contains(lowercaseQuery)
        }.sorted { episode1, episode2 in
            let dateFormatter = ISO8601DateFormatter()
            let date1 = dateFormatter.date(from: episode1.creationTime) ?? Date.distantPast
            let date2 = dateFormatter.date(from: episode2.creationTime) ?? Date.distantPast
            return date1 > date2
        }
    }
    
    func getShowsFromCategory(_ category: ShowCategory) -> [Show] {
        return showCollections.first { $0.category == category }?.shows ?? []
    }
    
    func getRecentEpisodes(limit: Int = 10) -> [Episode] {
        return allEpisodes
            .sorted { episode1, episode2 in
                let dateFormatter = ISO8601DateFormatter()
                let date1 = dateFormatter.date(from: episode1.creationTime) ?? Date.distantPast
                let date2 = dateFormatter.date(from: episode2.creationTime) ?? Date.distantPast
                return date1 > date2
            }
            .prefix(limit)
            .map { $0 }
    }
    
    // Find episode by video data ID
    func findEpisode(by videoDataId: String) -> Episode? {
        return allEpisodes.first { $0._id == videoDataId }
    }
    
    // Find show by episode ID
    func findShow(containing episodeId: String) -> Show? {
        return shows.first { show in
            show.episodes.contains { $0._id == episodeId }
        }
    }
}

// MARK: - CastrAPIService Extension for Show Collections
extension CastrAPIService {
    
    func createShowCollections(from shows: [Show]) {
        var collections: [ShowCollection] = []
        
        // 1. All Shows Collection (Always first)
        collections.append(ShowCollection(
            category: .all,
            shows: shows
        ))
        
        // 2. Group shows by their categories
        let groupedShows = Dictionary(grouping: shows) { $0.showCategory }
        
        for category in ShowCategory.allCases {
            if category == .all { continue }
            
            if let showsInCategory = groupedShows[category], !showsInCategory.isEmpty {
                collections.append(ShowCollection(
                    category: category,
                    shows: showsInCategory.sorted { show1, show2 in
                        if show1.episodeCount == show2.episodeCount {
                            return show1.displayName < show2.displayName
                        }
                        return show1.episodeCount > show2.episodeCount
                    }
                ))
            }
        }
        
        // Sort collections by total episodes (except "All Shows" which stays first)
        let allShowsCollection = collections.first { $0.category == .all }
        let otherCollections = collections.filter { $0.category != .all }
            .sorted { $0.totalEpisodes > $1.totalEpisodes }
        
        var finalCollections: [ShowCollection] = []
        if let allShows = allShowsCollection {
            finalCollections.append(allShows)
        }
        finalCollections.append(contentsOf: otherCollections)
        
        self.showCollections = finalCollections
    }
    
    // Backward compatibility method
    func createCategories(from episodes: [Episode]) {
        var categories: [Category] = []
        
        // Convert episodes to VideoData for backward compatibility
        let videoDataList = episodes.map { episode in
            self.convertEpisodeToVideoData(episode)
        }
        
        // Create basic categories for backward compatibility
        categories.append(Category(
            name: "All Videos",
            image: "all_videos",
            color: Color(red: 0.2, green: 0.6, blue: 1.0),
            videos: videoDataList
        ))
        
        // Group episodes by show category
        let groupedEpisodes = Dictionary(grouping: episodes) { episode in
            let show = shows.first { show in
                show.episodes.contains { $0._id == episode._id }
            }
            return show?.showCategory ?? .general
        }
        
        for (category, episodeList) in groupedEpisodes {
            if category != .all && !episodeList.isEmpty {
                let videoDataForCategory = episodeList.map { episode in
                    self.convertEpisodeToVideoData(episode)
                }
                
                categories.append(Category(
                    name: category.rawValue,
                    image: category.rawValue.lowercased().replacingOccurrences(of: " ", with: "_"),
                    color: category.color,
                    videos: videoDataForCategory
                ))
            }
        }
        
        self.categories = categories
    }
}
