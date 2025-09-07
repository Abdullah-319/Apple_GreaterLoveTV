import Foundation
import SwiftUI

// MARK: - Enhanced Watch Progress Manager (Debug-Free Version)
class WatchProgressManager: ObservableObject {
    static let shared = WatchProgressManager()
    
    @Published var watchProgress: [String: WatchProgress] = [:]
    private let userDefaults = UserDefaults.standard
    private let progressKey = "enhanced_episode_watch_progress"
    
    private init() {
        loadProgress()
        migrateOldProgressData()
    }
    
    // MARK: - Public Methods with Enhanced Show Tracking
    
    /// Update the watch progress for an episode with show information
    func updateProgress(for episodeId: String, currentTime: Double, duration: Double, episodeTitle: String, showName: String? = nil) {
        let progressPercentage = duration > 0 ? (currentTime / duration) * 100 : 0
        
        // Only save progress if episode is watched for more than 5% and less than 95%
        guard progressPercentage > 5 && progressPercentage < 95 else {
            // If episode is watched more than 95%, mark as completed and remove from continue watching
            if progressPercentage >= 95 {
                removeProgress(for: episodeId)
            }
            return
        }
        
        let progress = WatchProgress(
            episodeId: episodeId,
            episodeTitle: episodeTitle,
            showName: showName,
            currentTime: currentTime,
            duration: duration,
            progressPercentage: progressPercentage,
            lastWatched: Date()
        )
        
        DispatchQueue.main.async {
            self.watchProgress[episodeId] = progress
            self.saveProgress()
        }
    }
    
    // Backward compatibility method
    func updateProgress(for videoId: String, currentTime: Double, duration: Double, videoTitle: String) {
        updateProgress(for: videoId, currentTime: currentTime, duration: duration, episodeTitle: videoTitle, showName: nil)
    }
    
    /// Get watch progress for a specific episode
    func getProgress(for episodeId: String) -> WatchProgress? {
        return watchProgress[episodeId]
    }
    
    /// Get all episodes with continue watching progress, sorted by last watched
    func getContinueWatchingVideos() -> [WatchProgress] {
        let result = Array(watchProgress.values)
            .sorted { $0.lastWatched > $1.lastWatched }
            .prefix(20)
            .map { $0 }
        
        return result
    }
    
    /// Get continue watching episodes for a specific show
    func getContinueWatchingForShow(_ showName: String) -> [WatchProgress] {
        return Array(watchProgress.values)
            .filter { progress in
                guard let progressShowName = progress.showName else { return false }
                return progressShowName.lowercased() == showName.lowercased()
            }
            .sorted { $0.lastWatched > $1.lastWatched }
    }
    
    /// Get continue watching episodes grouped by show
    func getContinueWatchingByShow() -> [String: [WatchProgress]] {
        let allProgress = getContinueWatchingVideos()
        var groupedProgress: [String: [WatchProgress]] = [:]
        
        for progress in allProgress {
            let showName = progress.showName ?? "Unknown Show"
            if groupedProgress[showName] == nil {
                groupedProgress[showName] = []
            }
            groupedProgress[showName]?.append(progress)
        }
        
        return groupedProgress
    }
    
    /// Remove progress for a specific episode
    func removeProgress(for episodeId: String) {
        DispatchQueue.main.async {
            self.watchProgress.removeValue(forKey: episodeId)
            self.saveProgress()
        }
    }
    
    /// Clear all watch progress
    func clearAllProgress() {
        DispatchQueue.main.async {
            self.watchProgress.removeAll()
            self.saveProgress()
        }
    }
    
    /// Clear progress for a specific show
    func clearProgressForShow(_ showName: String) {
        DispatchQueue.main.async {
            let episodesToRemove = self.watchProgress.values
                .filter { progress in
                    guard let progressShowName = progress.showName else { return false }
                    return progressShowName.lowercased() == showName.lowercased()
                }
                .map { $0.episodeId }
            
            for episodeId in episodesToRemove {
                self.watchProgress.removeValue(forKey: episodeId)
            }
            
            self.saveProgress()
        }
    }
    
    /// Check if an episode has continue watching progress
    func hasProgress(for episodeId: String) -> Bool {
        return watchProgress[episodeId] != nil
    }
    
    /// Get formatted progress text for display
    func getProgressText(for episodeId: String) -> String? {
        guard let progress = getProgress(for: episodeId) else { return nil }
        
        let currentTimeFormatted = formatTime(progress.currentTime)
        let durationFormatted = formatTime(progress.duration)
        
        return "\(currentTimeFormatted) / \(durationFormatted) (\(Int(progress.progressPercentage))%)"
    }
    
    /// Get total watch time across all episodes
    func getTotalWatchTime() -> Double {
        return watchProgress.values.reduce(0) { $0 + $1.currentTime }
    }
    
    /// Get enhanced watch statistics
    func getWatchStatistics() -> [String: Any] {
        let totalProgress = watchProgress.values
        let groupedByShow = getContinueWatchingByShow()
        
        return [
            "total_episodes_in_progress": totalProgress.count,
            "total_watch_time_hours": getTotalWatchTime() / 3600,
            "average_completion_percentage": totalProgress.isEmpty ? 0 : totalProgress.map { $0.progressPercentage }.reduce(0, +) / Double(totalProgress.count),
            "shows_being_watched": groupedByShow.count,
            "most_recent_episode": totalProgress.max(by: { $0.lastWatched < $1.lastWatched })?.episodeTitle ?? "None",
            "most_watched_show": groupedByShow.max(by: { $0.value.count < $1.value.count })?.key ?? "None",
            "total_shows_with_progress": Set(totalProgress.compactMap { $0.showName }).count
        ]
    }
    
    // MARK: - Private Methods
    
    private func saveProgress() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(watchProgress)
            userDefaults.set(data, forKey: progressKey)
        } catch {
            // Silently handle save errors
        }
    }
    
    private func loadProgress() {
        guard let data = userDefaults.data(forKey: progressKey) else {
            return
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loadedProgress = try decoder.decode([String: WatchProgress].self, from: data)
            
            DispatchQueue.main.async {
                self.watchProgress = loadedProgress
            }
        } catch {
            migrateOldProgressData()
        }
    }
    
    private func migrateOldProgressData() {
        let oldProgressKeys = [
            "episode_watch_progress",
            "video_watch_progress",
            "watch_progress"
        ]
        
        var migratedProgress: [String: WatchProgress] = [:]
        var totalMigrated = 0
        
        for oldKey in oldProgressKeys {
            guard let data = userDefaults.data(forKey: oldKey) else { continue }
            
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                // Try to decode as new format first
                if let newProgress = try? decoder.decode([String: WatchProgress].self, from: data) {
                    for (key, progress) in newProgress {
                        migratedProgress[key] = progress
                        totalMigrated += 1
                    }
                    continue
                }
                
                // Try old format
                struct OldWatchProgress: Codable {
                    let videoId: String?
                    let episodeId: String?
                    let videoTitle: String?
                    let episodeTitle: String?
                    let showName: String?
                    let currentTime: Double
                    let duration: Double
                    let progressPercentage: Double
                    let lastWatched: Date
                }
                
                if let oldProgress = try? decoder.decode([String: OldWatchProgress].self, from: data) {
                    for (key, oldItem) in oldProgress {
                        let newProgress = WatchProgress(
                            episodeId: oldItem.episodeId ?? oldItem.videoId ?? key,
                            episodeTitle: oldItem.episodeTitle ?? oldItem.videoTitle ?? "Unknown Episode",
                            showName: oldItem.showName,
                            currentTime: oldItem.currentTime,
                            duration: oldItem.duration,
                            progressPercentage: oldItem.progressPercentage,
                            lastWatched: oldItem.lastWatched
                        )
                        migratedProgress[key] = newProgress
                        totalMigrated += 1
                    }
                }
                
                // Remove old data after successful migration
                userDefaults.removeObject(forKey: oldKey)
                
            } catch {
                // Silently handle migration errors
            }
        }
        
        if totalMigrated > 0 {
            DispatchQueue.main.async {
                self.watchProgress = migratedProgress
                self.saveProgress()
            }
        }
    }
    
    private func formatTime(_ seconds: Double) -> String {
        guard !seconds.isNaN && seconds.isFinite else { return "00:00" }
        
        let totalSeconds = Int(seconds)
        let hours = totalSeconds / 3600
        let minutes = (totalSeconds % 3600) / 60
        let remainingSeconds = totalSeconds % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
        } else {
            return String(format: "%02d:%02d", minutes, remainingSeconds)
        }
    }
    
    // MARK: - Analytics and Insights
    
    /// Get episodes that are almost finished (>80% watched)
    func getAlmostFinishedEpisodes() -> [WatchProgress] {
        return Array(watchProgress.values)
            .filter { $0.progressPercentage > 80 }
            .sorted { $0.lastWatched > $1.lastWatched }
    }
    
    /// Get episodes that were started but barely watched (<20%)
    func getBarelyStartedEpisodes() -> [WatchProgress] {
        return Array(watchProgress.values)
            .filter { $0.progressPercentage < 20 }
            .sorted { $0.lastWatched > $1.lastWatched }
    }
    
    /// Get the most frequently resumed episodes
    func getMostResumedEpisodes() -> [WatchProgress] {
        return Array(watchProgress.values)
            .filter { $0.progressPercentage >= 20 && $0.progressPercentage <= 80 }
            .sorted { $0.lastWatched > $1.lastWatched }
    }
    
    /// Check if user has been binge-watching a show (multiple episodes in progress)
    func getShowsBingeWatching() -> [String] {
        let groupedProgress = getContinueWatchingByShow()
        return groupedProgress.compactMap { (showName, episodes) in
            episodes.count >= 3 ? showName : nil
        }
    }
    
    /// Get watching streaks by show
    func getWatchingStreaksByShow() -> [String: Int] {
        let groupedProgress = getContinueWatchingByShow()
        var streaks: [String: Int] = [:]
        
        for (showName, episodes) in groupedProgress {
            let sortedEpisodes = episodes.sorted { $0.lastWatched > $1.lastWatched }
            
            var streak = 0
            var lastDate: Date?
            
            for episode in sortedEpisodes {
                if let last = lastDate {
                    let daysDifference = Calendar.current.dateComponents([.day], from: episode.lastWatched, to: last).day ?? 0
                    if daysDifference <= 1 {
                        streak += 1
                    } else {
                        break
                    }
                } else {
                    streak = 1
                }
                lastDate = episode.lastWatched
            }
            
            streaks[showName] = streak
        }
        
        return streaks
    }
    
    /// Get recommendations based on watching patterns
    func getRecommendations() -> [String] {
        let groupedProgress = getContinueWatchingByShow()
        var recommendations: [String] = []
        
        // Recommend shows with high completion rates
        for (showName, episodes) in groupedProgress {
            let averageCompletion = episodes.map { $0.progressPercentage }.reduce(0, +) / Double(episodes.count)
            if averageCompletion > 70 {
                recommendations.append("Continue watching \(showName) - you're really into this series!")
            }
        }
        
        // Recommend finishing almost-complete episodes
        let almostFinished = getAlmostFinishedEpisodes()
        for episode in almostFinished.prefix(3) {
            recommendations.append("Finish watching \"\(episode.episodeTitle)\" - only \(100 - Int(episode.progressPercentage))% left!")
        }
        
        return recommendations
    }
}
