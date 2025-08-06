import Foundation
import SwiftUI

// MARK: - Watch Progress Manager
class WatchProgressManager: ObservableObject {
    static let shared = WatchProgressManager()
    
    @Published var watchProgress: [String: WatchProgress] = [:]
    private let userDefaults = UserDefaults.standard
    private let progressKey = "video_watch_progress"
    
    private init() {
        loadProgress()
    }
    
    // MARK: - Public Methods
    
    /// Update the watch progress for a video
    func updateProgress(for videoId: String, currentTime: Double, duration: Double, videoTitle: String) {
        let progressPercentage = duration > 0 ? (currentTime / duration) * 100 : 0
        
        // Only save progress if video is watched for more than 5% and less than 95%
        guard progressPercentage > 5 && progressPercentage < 95 else {
            // If video is watched more than 95%, mark as completed and remove from continue watching
            if progressPercentage >= 95 {
                removeProgress(for: videoId)
            }
            return
        }
        
        let progress = WatchProgress(
            videoId: videoId,
            videoTitle: videoTitle,
            currentTime: currentTime,
            duration: duration,
            progressPercentage: progressPercentage,
            lastWatched: Date()
        )
        
        DispatchQueue.main.async {
            self.watchProgress[videoId] = progress
            self.saveProgress()
        }
    }
    
    /// Get watch progress for a specific video
    func getProgress(for videoId: String) -> WatchProgress? {
        return watchProgress[videoId]
    }
    
    /// Get all videos with continue watching progress, sorted by last watched
    func getContinueWatchingVideos() -> [WatchProgress] {
        return Array(watchProgress.values)
            .sorted { $0.lastWatched > $1.lastWatched }
            .prefix(10) // Limit to 10 most recent
            .map { $0 }
    }
    
    /// Remove progress for a specific video
    func removeProgress(for videoId: String) {
        DispatchQueue.main.async {
            self.watchProgress.removeValue(forKey: videoId)
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
    
    /// Check if a video has continue watching progress
    func hasProgress(for videoId: String) -> Bool {
        return watchProgress[videoId] != nil
    }
    
    /// Get formatted progress text for display
    func getProgressText(for videoId: String) -> String? {
        guard let progress = getProgress(for: videoId) else { return nil }
        
        let currentTimeFormatted = formatTime(progress.currentTime)
        let durationFormatted = formatTime(progress.duration)
        
        return "\(currentTimeFormatted) / \(durationFormatted) (\(Int(progress.progressPercentage))%)"
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
}
