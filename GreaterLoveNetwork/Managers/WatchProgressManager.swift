import Foundation
import SwiftUI

// MARK: - Enhanced Watch Progress Manager for Shows and Episodes
class WatchProgressManager: ObservableObject {
    static let shared = WatchProgressManager()
    
    @Published var watchProgress: [String: WatchProgress] = [:]
    private let userDefaults = UserDefaults.standard
    private let progressKey = "episode_watch_progress" // updated key name
    
    private init() {
        loadProgress()
        // Migrate old progress data if needed
        migrateOldProgressData()
    }
    
    // MARK: - Public Methods
    
    /// Update the watch progress for an episode
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
        return Array(watchProgress.values)
            .sorted { $0.lastWatched > $1.lastWatched }
            .prefix(15) // Increased limit for more episodes
            .map { $0 }
    }
    
    /// Get continue watching episodes for a specific show
    func getContinueWatchingForShow(_ showName: String) -> [WatchProgress] {
        return Array(watchProgress.values)
            .filter { $0.showName?.lowercased() == showName.lowercased() }
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
                .filter { $0.showName?.lowercased() == showName.lowercased() }
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
    
    /// Get watch statistics
    func getWatchStatistics() -> [String: Any] {
        let totalProgress = watchProgress.values
        
        return [
            "total_episodes_in_progress": totalProgress.count,
            "total_watch_time_hours": getTotalWatchTime() / 3600,
            "average_completion_percentage": totalProgress.isEmpty ? 0 : totalProgress.map { $0.progressPercentage }.reduce(0, +) / Double(totalProgress.count),
            "shows_being_watched": Set(totalProgress.compactMap { $0.showName }).count,
            "most_recent_episode": totalProgress.max(by: { $0.lastWatched < $1.lastWatched })?.episodeTitle ?? "None"
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
            print("Failed to save watch progress: \(error)")
        }
    }
    
    private func loadProgress() {
        guard let data = userDefaults.data(forKey: progressKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let loadedProgress = try decoder.decode([String: WatchProgress].self, from: data)
            
            DispatchQueue.main.async {
                self.watchProgress = loadedProgress
            }
        } catch {
            print("Failed to load watch progress: \(error)")
            // Try to migrate from old format
            migrateOldProgressData()
        }
    }
    
    private func migrateOldProgressData() {
        // Try to load old progress data with the old key
        let oldProgressKey = "video_watch_progress"
        guard let data = userDefaults.data(forKey: oldProgressKey) else { return }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            
            // Create a temporary struct for old format
            struct OldWatchProgress: Codable {
                let videoId: String
                let videoTitle: String
                let currentTime: Double
                let duration: Double
                let progressPercentage: Double
                let lastWatched: Date
            }
            
            let oldProgress = try decoder.decode([String: OldWatchProgress].self, from: data)
            
            // Convert to new format
            var migratedProgress: [String: WatchProgress] = [:]
            for (key, oldItem) in oldProgress {
                let newProgress = WatchProgress(
                    episodeId: oldItem.videoId,
                    episodeTitle: oldItem.videoTitle,
                    showName: nil, // We don't have show info in old format
                    currentTime: oldItem.currentTime,
                    duration: oldItem.duration,
                    progressPercentage: oldItem.progressPercentage,
                    lastWatched: oldItem.lastWatched
                )
                migratedProgress[key] = newProgress
            }
            
            DispatchQueue.main.async {
                self.watchProgress = migratedProgress
                self.saveProgress() // Save in new format
                
                // Remove old data
                self.userDefaults.removeObject(forKey: oldProgressKey)
            }
            
            print("Successfully migrated \(migratedProgress.count) watch progress items to new format")
            
        } catch {
            print("Failed to migrate old watch progress: \(error)")
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
        // For now, this returns episodes with moderate progress (20-80%)
        // In a full implementation, you'd track resume counts
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
}
